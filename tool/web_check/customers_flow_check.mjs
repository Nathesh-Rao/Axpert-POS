// Needs a build/run WITH --dart-define=SKIP_ENTRY=true (starts on the POS page, no splash/login); see entry.mjs.
// Release-build check that customers and points really persist in Drift (D2):
//   python3 tool/web_check/serve.py build/web 8300 &
//   node --experimental-websocket tool/web_check/customers_flow_check.mjs http://127.0.0.1:8300/ <outDir>
// Fresh profile. Through the UI: add customer "Zed Test", pick Priya Nair
// (Priya Nair, 400 points), add one item, redeem 10 points, complete a cash
// sale. Then RELOAD and rebuild the SQLite file from IndexedDB (sqlite3 CLI,
// temp copy deleted) and check: both customers' rows are there, Priya has 390
// points, the marker exists, LocalStore holds the same list (dual-write), no
// stale key, no console errors. Exit 1 on any mismatch.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';

const [url, outDir = '/tmp/customers_flow'] = process.argv.slice(2);
fs.mkdirSync(outDir, { recursive: true });
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const port = 9300 + Math.floor(Math.random() * 500);
const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, '--window-size=1280,720', '--user-data-dir=/tmp/custflow-' + port, 'about:blank'], { stdio: 'ignore' });
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

await send('Page.navigate', { url });
await waitView();
await click(519, 103); await sleep(1200);                       // Add customer dialog
await click(640, 293); await insert('Zed Test'); await sleep(200);
await click(640, 393); await insert('9876500001'); await sleep(200);
await shot('1_add_dialog_filled');
await click(640, 560); await sleep(1500);                        // Save customer
await click(190, 103); await sleep(800); await click(166, 256); await sleep(1000); // picker -> Priya Nair
await click(640, 28); await insert('8901234567895'); await key('Enter', 13); await sleep(1200); // one Lays
await click(1190, 413); await insert('10'); await sleep(600);    // redeem 10 points
await shot('2_before_checkout');
await key('F2', 113); await sleep(800);
await key('Enter', 13); await sleep(3500);                       // complete cash sale
await shot('3_after_checkout');
const lsBefore = JSON.parse(JSON.parse(await ev("localStorage.getItem('flutter.axpert-customers')") ?? 'null') ?? 'null');
const salesStored = JSON.parse(JSON.parse(await ev("localStorage.getItem('flutter.axpert-sales')") ?? '"[]"') ?? '[]');
console.log('before reload: LocalStore customers', lsBefore?.map((c) => `${c.id}:${c.name}:${c.points}`).join(', '), '| sales stored', salesStored.length);

await send('Page.reload');
await waitView();
await sleep(3000);
await shot('4_after_reload');

const dump = await ev(`new Promise((res)=>{const q=indexedDB.open('axpert_pos');q.onerror=()=>res(null);q.onsuccess=()=>{const db=q.result;const get=(n)=>new Promise(r=>{const rows=[];db.transaction(n).objectStore(n).openCursor().onsuccess=e=>{const c=e.target.result;if(!c){r(rows);return}rows.push([c.key,c.value]);c.continue()}});(async()=>{const files=await get('files');const blocks=await get('blocks');const b64=(buf)=>{let s='';const a=new Uint8Array(buf);for(let i=0;i<a.length;i++)s+=String.fromCharCode(a[i]);return btoa(s)};db.close();res(JSON.stringify({files:files.map(([k,v])=>({id:k,name:v.name,length:v.length})),blocks:blocks.map(([k,v])=>({file:k[0],offset:k[1],data:b64(v)}))}))})()}})`);
const tmp = `/tmp/customers_flow_db_${port}.sqlite`;
let rows = null, marker = null, problem = null;
try {
  const d = JSON.parse(dump);
  const file = d.files.find((f) => f.name === '/database');
  const parts = d.blocks.filter((b) => b.file === file.id).sort((a, b) => a.offset - b.offset);
  fs.writeFileSync(tmp, Buffer.concat(parts.map((b) => Buffer.from(b.data, 'base64'))).subarray(0, file.length));
  const q = (sql) => JSON.parse(execFileSync('sqlite3', ['-readonly', '-json', tmp, sql], { encoding: 'utf8' }) || '[]');
  rows = q('SELECT id, legacy_id, position, name, phone, points, deleted_at FROM customers ORDER BY position');
  marker = q("SELECT value FROM migration_state WHERE key = 'customers_copy_v1'");
} catch (e) { problem = String(e).slice(0, 200); } finally { fs.rmSync(tmp, { force: true }); }
const lsAfter = JSON.parse(JSON.parse(await ev("localStorage.getItem('flutter.axpert-customers')") ?? 'null') ?? 'null');
const stale = await ev("localStorage.getItem('flutter.axpert-customers-drift-stale')");
console.log('Drift customers rows after reload:', problem ? 'NOT READ ' + problem : JSON.stringify(rows.map((r) => `${r.position}:${r.legacy_id}:${r.name}:${r.points}${r.deleted_at ? ':deleted' : ''}`)));
console.log('marker:', marker?.length === 1 ? 'present' : 'MISSING', '| LocalStore customers after reload:', lsAfter?.map((c) => `${c.id}:${c.points}`).join(', '), '| stale key:', stale);
const uuid = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
const priya = rows?.find((r) => r.legacy_id === '3'), zed = rows?.find((r) => r.name === 'Zed Test');
const ok = !!rows && rows.length === 5 && priya?.points === 390 && !!zed && zed.position === 4 && zed.phone === '9876500001' && rows.every((r) => uuid.test(r.id) && !r.deleted_at)
  && marker?.length === 1 && lsAfter?.length === 5 && lsAfter.find((c) => c.id === '3')?.points === 390 && stale === null && salesStored.length === 1 && logs.length === 0;
console.log('console errors:', logs.length, logs.slice(0, 2).join(' | ').slice(0, 300));
console.log(ok ? 'CUSTOMERS FLOW CHECK OK (new customer and deducted points are in the Drift rows after reload)' : 'CUSTOMERS FLOW CHECK FAILED');
ws.close(); proc.kill();
process.exit(ok ? 0 : 1);
