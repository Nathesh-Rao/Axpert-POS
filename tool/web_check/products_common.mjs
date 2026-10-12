// Shared helpers for products_flow_check.mjs and products_10k_check.mjs (D4):
// headless Chrome over CDP, console capture (errors and `[startup]`/`[perf]`
// lines of a STARTUP_TIMELINE build) and a reader for the Drift SQLite file
// that the web build keeps in IndexedDB (rebuilt in a temp file, deleted).
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';

export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
export const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;

export async function launch({ width = 1280, height = 720, tag = 'prod', userDataDir = null } = {}) {
  const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
  const port = 9300 + Math.floor(Math.random() * 500);
  const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, `--window-size=${width},${height}`, `--user-data-dir=${userDataDir ?? `/tmp/${tag}-${port}`}`, 'about:blank'], { stdio: 'ignore' });
  let targets;
  for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {} await sleep(200); }
  const ws = new WebSocket(targets.find((t) => t.type === 'page').webSocketDebuggerUrl);
  await new Promise((r) => (ws.onopen = r));
  let id = 0; const pending = new Map(); const errors = []; const lines = [];
  ws.onmessage = (m) => {
    const d = JSON.parse(m.data);
    if (d.id && pending.has(d.id)) { pending.get(d.id)(d.result); pending.delete(d.id); }
    else if (d.method === 'Runtime.consoleAPICalled') {
      const text = d.params.args.map((a) => a.value ?? a.description).join(' ');
      if (['error', 'assert'].includes(d.params.type)) errors.push(text);
      else if (text.startsWith('[startup]') || text.startsWith('[perf]')) lines.push(text);
    }
    else if (d.method === 'Runtime.exceptionThrown') errors.push('EXCEPTION ' + (d.params.exceptionDetails.exception?.description ?? d.params.exceptionDetails.text));
    else if (d.method === 'Log.entryAdded' && d.params.entry.level === 'error') errors.push(d.params.entry.text + ' ' + (d.params.entry.url ?? ''));
  };
  const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
  const ev = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true })).result?.value;
  await send('Runtime.enable'); await send('Log.enable'); await send('Page.enable');
  await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
  const click = async (x, y) => { await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y }); await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 }); await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 }); };
  const insert = (text) => send('Input.insertText', { text });
  const key = async (k, vk) => { await send('Input.dispatchKeyEvent', { type: 'keyDown', key: k, code: k, windowsVirtualKeyCode: vk }); await send('Input.dispatchKeyEvent', { type: 'keyUp', key: k, code: k, windowsVirtualKeyCode: vk }); };
  const shot = async (dir, name) => { const r = await send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync(`${dir}/${name}.png`, Buffer.from(r.data, 'base64')); };
  const waitView = async (settleMs = 9000) => { for (let i = 0; i < 1200; i++) { if (await ev("!!document.querySelector('flutter-view, flt-glass-pane')")) break; await sleep(100); } await sleep(settleMs); };
  const close = () => { try { ws.close(); } catch {} proc.kill(); };
  const kill = () => { try { proc.kill('SIGKILL'); } catch {} };
  return { port, send, ev, click, insert, key, shot, waitView, errors, lines, close, kill };
}

/** localStorage value written by shared_preferences web (JSON of a JSON string). */
export const lsRead = async (ev, k) => {
  const raw = await ev(`localStorage.getItem('flutter.${k}')`);
  return raw == null ? null : JSON.parse(JSON.parse(raw));
};
export const lsRaw = (ev, k) => ev(`localStorage.getItem('flutter.${k}')`);

/** Reads the Drift SQLite file from IndexedDB and runs `fn(q)` where q(sql) returns rows. */
export async function withDb(ev, port, fn) {
  const dump = await ev(`new Promise((res)=>{const q=indexedDB.open('axpert_pos');q.onerror=()=>res(null);q.onsuccess=()=>{const db=q.result;const get=(n)=>new Promise(r=>{const rows=[];db.transaction(n).objectStore(n).openCursor().onsuccess=e=>{const c=e.target.result;if(!c){r(rows);return}rows.push([c.key,c.value]);c.continue()}});(async()=>{const files=await get('files');const blocks=await get('blocks');const b64=(buf)=>{let s='';const a=new Uint8Array(buf);for(let i=0;i<a.length;i++)s+=String.fromCharCode(a[i]);return btoa(s)};db.close();res(JSON.stringify({files:files.map(([k,v])=>({id:k,name:v.name,length:v.length})),blocks:blocks.map(([k,v])=>({file:k[0],offset:k[1],data:b64(v)}))}))})()}})`);
  const tmp = `/tmp/products_check_db_${port}.sqlite`;
  try {
    const d = JSON.parse(dump);
    const file = d.files.find((f) => f.name === '/database');
    const parts = d.blocks.filter((b) => b.file === file.id).sort((a, b) => a.offset - b.offset);
    fs.writeFileSync(tmp, Buffer.concat(parts.map((b) => Buffer.from(b.data, 'base64'))).subarray(0, file.length));
    const q = (sql) => JSON.parse(execFileSync('sqlite3', ['-readonly', '-json', tmp, sql], { encoding: 'utf8', maxBuffer: 256 * 1024 * 1024 }) || '[]');
    return await fn(q);
  } finally { fs.rmSync(tmp, { force: true }); }
}

export function bootstrapUrl(url) { return url; }
