// Logout check (DEC-150) against a `flutter run -d web-server` with
//   --dart-define=DEMO_SEED=true   (NO SKIP_ENTRY: the real splash and login)
//   node --experimental-websocket tool/web_check/logout_check.mjs http://127.0.0.1:<port>/ <outDir> [width height] [--back]
// (--back, on a fresh run: cashier1 logs out, then browser Back must not return to POS.)
// Logs in as cashier1, logs out through the user menu and expects the login
// screen (browser Back does not return to POS); logs in as admin (two stores:
// the picker) and expects the admin-only Database export row on the Settings
// page, which cashier1 does not get.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';


const [url, outDir = '/tmp/logout_check', widthArg = '1280', heightArg = '720'] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
const width = Number(widthArg), height = Number(heightArg);
fs.mkdirSync(outDir, { recursive: true });
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const port = 9300 + Math.floor(Math.random() * 500);
const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, `--window-size=${width},${height}`, '--user-data-dir=/tmp/demochk-' + port, 'about:blank'], { stdio: 'ignore' });
let targets;
for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {} await sleep(200); }
const ws = new WebSocket(targets.find((t) => t.type === 'page').webSocketDebuggerUrl);
await new Promise((r) => (ws.onopen = r));
let id = 0; const pending = new Map(); const logs = [];
ws.onmessage = (m) => {
  const d = JSON.parse(m.data);
  if (d.id && pending.has(d.id)) { pending.get(d.id)(d.result); pending.delete(d.id); }
  else if (d.method === 'Runtime.consoleAPICalled' && ['error', 'assert'].includes(d.params.type)) logs.push(d.params.args.map((a) => a.value ?? a.description).join(' '));
  else if (d.method === 'Runtime.exceptionThrown') logs.push('EXCEPTION ' + (d.params.exceptionDetails.exception?.description ?? d.params.exceptionDetails.text));
  else if (d.method === 'Log.entryAdded' && d.params.entry.level === 'error') logs.push(d.params.entry.text + ' ' + (d.params.entry.url ?? ''));
};
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
const ev = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true })).result?.value;
await send('Runtime.enable'); await send('Log.enable'); await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
const click = async (x, y) => { await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y }); await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 }); await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 }); };
const insert = (text) => send('Input.insertText', { text });
const key = async (k, vk) => { await send('Input.dispatchKeyEvent', { type: 'keyDown', key: k, code: k, windowsVirtualKeyCode: vk }); await send('Input.dispatchKeyEvent', { type: 'keyUp', key: k, code: k, windowsVirtualKeyCode: vk }); };
const shot = async (name) => { const r = await send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync(`${outDir}/${name}.png`, Buffer.from(r.data, 'base64')); };
const load = async () => {
  await send('Page.navigate', { url });
  const t0 = Date.now();
  while (Date.now() - t0 < 60000) { if (await ev("!!document.querySelector('flutter-view, flt-glass-pane')")) break; await sleep(200); }
  await sleep(7000);
};
const enableSemantics = async () => { await ev("(()=>{const p=document.querySelector('flt-semantics-placeholder'); if(p) p.click()})()"); await sleep(2500); };

// The database file, rebuilt from the IndexedDB blocks (see drift_check.mjs).
async function query(sqls) {
  const dump = await ev(`new Promise((res)=>{const q=indexedDB.open('axpert_pos');q.onerror=()=>res(null);q.onsuccess=()=>{const db=q.result;const get=(n)=>new Promise(r=>{const rows=[];db.transaction(n).objectStore(n).openCursor().onsuccess=e=>{const c=e.target.result;if(!c){r(rows);return}rows.push([c.key,c.value]);c.continue()}});(async()=>{const files=await get('files');const blocks=await get('blocks');const b64=(buf)=>{let s='';const a=new Uint8Array(buf);for(let i=0;i<a.length;i++)s+=String.fromCharCode(a[i]);return btoa(s)};db.close();res(JSON.stringify({files:files.map(([k,v])=>({id:k,name:v.name,length:v.length})),blocks:blocks.map(([k,v])=>({file:k[0],offset:k[1],data:b64(v)}))}))})()}})`);
  const d = JSON.parse(dump);
  const file = d.files.find((f) => f.name === '/database');
  const parts = d.blocks.filter((b) => b.file === file.id).sort((a, b) => a.offset - b.offset);
  const tmp = `/tmp/logout_check_db_${port}.sqlite`;
  fs.writeFileSync(tmp, Buffer.concat(parts.map((b) => Buffer.from(b.data, 'base64'))).subarray(0, file.length));
  try { return sqls.map((s) => JSON.parse(execFileSync('sqlite3', ['-readonly', '-json', tmp, s], { encoding: 'utf8' }) || '[]')); }
  finally { fs.rmSync(tmp, { force: true }); }
}

const checks = [];
const check = (name, ok, detail = '') => { checks.push({ name, ok }); console.log(`${ok ? 'ok  ' : 'FAIL'} | ${name} ${detail}`); };

// Visible text through the accessibility tree (Flutter draws on a canvas).
const html = async () => { await enableSemantics(); return ev('document.body.innerHTML'); };
// Clicks the first semantics node whose label or text equals `label`.
const clickLabel = async (label) => {
  const box = await ev(`(()=>{const m=[...document.querySelectorAll('flt-semantics')].filter(n=>((n.getAttribute('aria-label')||n.textContent||'').trim()===${JSON.stringify(label)}));const rs=m.map(n=>n.getBoundingClientRect()).filter(r=>r.width>0&&r.height>0);if(!rs.length)return null;const r=rs[0];return {x:r.x+r.width/2,y:r.y+r.height/2}})()`);
  if (!box) return false;
  await click(box.x, box.y); await sleep(900);
  return true;
};
const login = async (user, pass) => {
  await sleep(1500); // the debug build needs a moment before the field takes text
  await insert(user); await key('Tab', 9); await insert(pass); await key('Enter', 13); await sleep(3500);
};

await load();
await sleep(3500); // splash, then login (semantics stay off until signed in)
await shot('00_login');
await login('cashier1', 'Demo#Cashier1');
await shot('01_cashier_pos');
let h = await html();
check('cashier1 is in: the POS screen, not the login', h.includes('Bill Summary') && !h.includes('Sign In'));

// Settings (More): cashier1 has no Database export row.
await clickLabel('More'); await sleep(900);
h = await html();
await shot('02_cashier_settings');
check('cashier1: no Database export row', !h.includes('Export database'));
await clickLabel('POS'); await sleep(600);

// Logout through the user menu.
check('user menu opens', await clickLabel('More options'));
check('Logout is in the user menu', await clickLabel('Logout'));
await sleep(2500);
await shot('03_after_logout');
h = await html();
check('after Logout: the login screen is shown', h.includes('Sign In'));
check('after Logout: no signed-in POS or Counter closed card', !h.includes('Counter closed') && !h.includes('Bill Summary'));
if (process.argv.includes('--back')) {
  // Second run (one page load per `flutter run`): browser Back must not return to POS.
  const urlBefore = await ev('location.href');
  await ev('history.back()'); await sleep(1500);
  const urlBack = await ev('location.href');
  check('browser Back does not return to a signed-in page', urlBack === 'about:blank' || !(await html()).includes('Bill Summary'), `${urlBefore} -> ${urlBack}`);
  check('no console errors', logs.length === 0, logs.slice(0, 2).join(' | ').slice(0, 200));
  const bad = checks.filter((c) => !c.ok);
  console.log(`\n${checks.length} checks, ${bad.length} failed.`);
  ws.close(); proc.kill();
  process.exit(bad.length ? 1 : 0);
}

// admin: two stores, so the picker comes first.
await login('admin', 'Demo#Admin1');
await shot('04_admin_picker');
h = await html();
check('admin gets the store picker, signed in as Asha Admin (Administrator)', h.includes('Asha Admin') && h.includes('Administrator'), h.includes('Choose store') ? '' : 'picker text not found');
await click(width * 0.797, height * 0.76); // Continue (1280x720 layout)
await sleep(3500);
await shot('05_admin_pos');
h = await html();
check('admin is in: the POS screen, no cashier name', h.includes('Bill Summary') && !h.includes('Chitra Cashier'));
await clickLabel('More'); await sleep(900);
h = await html();
await shot('06_admin_settings');
check('admin: the Database export row is there', h.includes('Export database'));
check('no console errors', logs.length === 0, logs.slice(0, 2).join(' | ').slice(0, 200));
const failed = checks.filter((c) => !c.ok);
console.log(`\n${checks.length} checks, ${failed.length} failed. Screenshots in ${outDir}`);
ws.close(); proc.kill();
process.exit(failed.length ? 1 : 0);
