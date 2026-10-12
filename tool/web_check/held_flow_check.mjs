// Release-build check that held bills persist in Drift (D3):
//   python3 tool/web_check/serve.py build/web 8300 &
//   node --experimental-websocket tool/web_check/held_flow_check.mjs http://127.0.0.1:8300/ <outDir>
// Fresh profile, 1280x720. Through the UI (keys and clicks, no code access):
//   1. add Lays, F4 (hold), RELOAD, read the Drift rows: one active held_bills row
//      with that ref, position 0 and the cart snapshot; LocalStore has the same ref.
//   2. F5, click the held bill (recall works on a bill loaded from Drift), RELOAD:
//      the row is a tombstone (deleted_at set, cart_json kept, never deleted), no
//      active rows, LocalStore held is [], the recalled cart is in the stored cart.
//   3. hold the recalled cart again, add Coke, hold again, RELOAD: two active rows
//      at positions 0 and 1 in hold order, the old tombstone still there.
// The SQLite file is rebuilt from IndexedDB (sqlite3 CLI, temp copy deleted).
// Exit 1 on any mismatch or console error.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';

const [url, outDir = '/tmp/held_flow'] = process.argv.slice(2);
fs.mkdirSync(outDir, { recursive: true });
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const port = 9300 + Math.floor(Math.random() * 500);
const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, '--window-size=1280,720', '--user-data-dir=/tmp/heldflow-' + port, 'about:blank'], { stdio: 'ignore' });
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
await send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });
const click = async (x, y) => { await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y }); await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 }); await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 }); };
const insert = (text) => send('Input.insertText', { text });
const key = async (k, vk) => { await send('Input.dispatchKeyEvent', { type: 'keyDown', key: k, code: k, windowsVirtualKeyCode: vk }); await send('Input.dispatchKeyEvent', { type: 'keyUp', key: k, code: k, windowsVirtualKeyCode: vk }); };
const shot = async (name) => { const r = await send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync(`${outDir}/${name}.png`, Buffer.from(r.data, 'base64')); };
const waitView = async () => { for (let i = 0; i < 600; i++) { if (await ev("!!document.querySelector('flutter-view, flt-glass-pane')")) break; await sleep(100); } await sleep(9000); };
const addByBarcode = async (code) => { await click(640, 28); await insert(code); await key('Enter', 13); await sleep(1200); };
const ls = async (k) => { const raw = await ev(`localStorage.getItem('flutter.${k}')`); return raw == null ? null : JSON.parse(JSON.parse(raw)); };

async function driftRows() {
  const dump = await ev(`new Promise((res)=>{const q=indexedDB.open('axpert_pos');q.onerror=()=>res(null);q.onsuccess=()=>{const db=q.result;const get=(n)=>new Promise(r=>{const rows=[];db.transaction(n).objectStore(n).openCursor().onsuccess=e=>{const c=e.target.result;if(!c){r(rows);return}rows.push([c.key,c.value]);c.continue()}});(async()=>{const files=await get('files');const blocks=await get('blocks');const b64=(buf)=>{let s='';const a=new Uint8Array(buf);for(let i=0;i<a.length;i++)s+=String.fromCharCode(a[i]);return btoa(s)};db.close();res(JSON.stringify({files:files.map(([k,v])=>({id:k,name:v.name,length:v.length})),blocks:blocks.map(([k,v])=>({file:k[0],offset:k[1],data:b64(v)}))}))})()}})`);
  const tmp = `/tmp/held_flow_db_${port}.sqlite`;
  try {
    const d = JSON.parse(dump);
    const file = d.files.find((f) => f.name === '/database');
    const parts = d.blocks.filter((b) => b.file === file.id).sort((a, b) => a.offset - b.offset);
    fs.writeFileSync(tmp, Buffer.concat(parts.map((b) => Buffer.from(b.data, 'base64'))).subarray(0, file.length));
    const q = (sql) => JSON.parse(execFileSync('sqlite3', ['-readonly', '-json', tmp, sql], { encoding: 'utf8' }) || '[]');
    return {
      rows: q('SELECT id, ref, position, held_at, cart_json, created_at, updated_at, deleted_at FROM held_bills ORDER BY created_at, position'),
      marker: q("SELECT value FROM migration_state WHERE key = 'held_copy_v1'"),
      version: q('PRAGMA user_version')[0]?.user_version,
    };
  } catch (e) { return { problem: String(e).slice(0, 200) }; } finally { fs.rmSync(tmp, { force: true }); }
}
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
const checks = [];
const check = (name, ok, detail = '') => { checks.push(ok); console.log(ok ? 'ok  ' : 'FAIL', name, detail); };
const show = (r) => r.problem ? 'NOT READ ' + r.problem : JSON.stringify(r.rows.map((x) => `${x.ref}@${x.position}${x.deleted_at ? ':deleted' : ''}`));

// ---- 1. hold, reload ----
await send('Page.navigate', { url });
await waitView();
await addByBarcode('8901234567895');                       // Lays Classic 52g
await key('F4', 115); await sleep(2000);
await shot('1_after_hold');
const heldBefore = await ls('axpert-held');
console.log('1. before reload: LocalStore held =', heldBefore?.map((b) => b.ref).join(','));
await send('Page.reload'); await waitView(); await sleep(2000);
let r = await driftRows();
console.log('   Drift rows after reload:', show(r));
const ref1 = heldBefore?.[0]?.ref;
check('1 one active row with the held ref, position 0, snapshot kept',
  !r.problem && r.rows.length === 1 && r.rows[0].ref === ref1 && /^H\d{1,6}$/.test(ref1) && r.rows[0].position === 0 && !r.rows[0].deleted_at && uuid.test(r.rows[0].id) && r.rows[0].cart_json.includes('Lays Classic 52g') && r.rows[0].held_at === heldBefore[0].time);
check('1 marker held_copy_v1 present, user_version 5', !r.problem && r.marker?.length === 1 && r.version === 5);
check('1 no stale key', (await ls('axpert-held-drift-stale')) === null);

// ---- 2. recall (bill came from Drift), reload ----
await key('F5', 116); await sleep(1500);
await shot('2_recall_dialog_after_reload');
await click(640, 404); await sleep(2000);                  // the held bill row
await shot('3_after_recall');
const cartAfterRecall = await ls('axpert-cart');
console.log('2. after recall: LocalStore held =', JSON.stringify(await ls('axpert-held')), '| cart lines =', cartAfterRecall?.lines?.length);
await send('Page.reload'); await waitView(); await sleep(2000);
r = await driftRows();
console.log('   Drift rows after reload:', show(r));
check('2 the recalled bill is a tombstone (deleted_at set, cart_json kept, not deleted)',
  !r.problem && r.rows.length === 1 && r.rows[0].ref === ref1 && !!r.rows[0].deleted_at && r.rows[0].cart_json.includes('Lays Classic 52g'));
check('2 LocalStore held is [] and the recalled cart survived the reload',
  JSON.stringify(await ls('axpert-held')) === '[]' && (await ls('axpert-cart'))?.lines?.length === 1);

// ---- 3. two new holds, reload ----
await key('F4', 115); await sleep(1500);                    // hold the recalled cart again
await addByBarcode('8901234567890');                        // Coca Cola 500ml
await key('F4', 115); await sleep(2000);
const heldTwo = await ls('axpert-held');
await send('Page.reload'); await waitView(); await sleep(2000);
await shot('4_after_two_holds_reload');
r = await driftRows();
console.log('3. LocalStore held =', heldTwo?.map((b) => b.ref).join(','), '| Drift rows after reload:', show(r));
const active = r.rows?.filter((x) => !x.deleted_at) ?? [];
check('3 two active rows at positions 0 and 1 in hold order, old tombstone kept',
  !r.problem && r.rows.length === 3 && active.length === 2 && active.map((x) => x.position).join() === '0,1' && active.map((x) => x.ref).join() === heldTwo.map((b) => b.ref).join()
  && active[0].cart_json.includes('Lays Classic 52g') && active[1].cart_json.includes('Coca Cola 500ml') && r.rows.some((x) => x.ref === ref1 && x.deleted_at));
check('3 no console errors', logs.length === 0, logs.slice(0, 2).join(' | ').slice(0, 300));

const ok = checks.every(Boolean);
console.log(ok ? 'HELD FLOW CHECK OK (hold, recall and reload agree with the Drift rows)' : 'HELD FLOW CHECK FAILED');
ws.close(); proc.kill();
process.exit(ok ? 0 : 1);
