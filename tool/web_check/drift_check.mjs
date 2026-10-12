// Release-build check that the Drift web database really loads (DEC-117/119):
//   python3 tool/web_check/serve.py build/web 8300 &
//   node --experimental-websocket tool/web_check/drift_check.mjs http://127.0.0.1:8300/ <outDir> [width height]
// Reports: HTTP status, size and content type of drift_worker.js and sqlite3.wasm
// (probed with fetch: the worker's own requests are not visible to the page),
// console errors, the browser storage the database created (IndexedDB names and
// OPFS entries), the device_context_entries row (read from a temp copy of the
// database file rebuilt from the IndexedDB blocks with the `sqlite3` CLI, then
// deleted), the settings rows, the settings_copy_v1 marker and user_version 3
// (D1) and the time until the first Flutter view. Exit 1 on a problem.
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import { execFileSync } from 'node:child_process';

const [url, outDir = '/tmp/drift_check', widthArg = '1280', heightArg = '720'] = process.argv.slice(2);
const width = Number(widthArg), height = Number(heightArg);
fs.mkdirSync(outDir, { recursive: true });
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const port = 9300 + Math.floor(Math.random() * 500);
const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, `--window-size=${width},${height}`, '--user-data-dir=/tmp/driftchk-' + port, 'about:blank'], { stdio: 'ignore' });
let targets;
for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {} await sleep(200); }
const ws = new WebSocket(targets.find((t) => t.type === 'page').webSocketDebuggerUrl);
await new Promise((r) => (ws.onopen = r));
let id = 0; const pending = new Map(); const logs = []; const responses = {};
ws.onmessage = (m) => {
  const d = JSON.parse(m.data);
  if (d.id && pending.has(d.id)) { pending.get(d.id)(d.result); pending.delete(d.id); }
  else if (d.method === 'Runtime.consoleAPICalled' && ['error', 'assert'].includes(d.params.type)) logs.push(d.params.args.map((a) => a.value ?? a.description).join(' '));
  else if (d.method === 'Runtime.exceptionThrown') logs.push('EXCEPTION ' + (d.params.exceptionDetails.exception?.description ?? d.params.exceptionDetails.text));
  else if (d.method === 'Log.entryAdded' && d.params.entry.level === 'error') logs.push(d.params.entry.text + ' ' + (d.params.entry.url ?? ''));
  else if (d.method === 'Network.responseReceived') {
    const u = d.params.response.url;
    if (/drift_worker\.js|sqlite3\.wasm/.test(u)) responses[u.split('/').pop().split('?')[0]] = { status: d.params.response.status, type: d.params.response.mimeType, from: d.params.type };
  }
};
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
const ev = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true })).result?.value;
await send('Runtime.enable'); await send('Log.enable'); await send('Page.enable'); await send('Network.enable');
await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
const t0 = Date.now();
await send('Page.navigate', { url });
let firstViewMs = null;
while (Date.now() - t0 < 60000) { if (await ev("!!document.querySelector('flutter-view, flt-glass-pane')")) { firstViewMs = Date.now() - t0; break; } await sleep(100); }
await sleep(6000);
const storage = await ev(`(async()=>{const r={};try{r.indexedDB=(await indexedDB.databases()).map(d=>d.name)}catch(e){r.indexedDB='n/a '+e}
try{const root=await navigator.storage.getDirectory();const names=[];for await(const [n] of root.entries())names.push(n);r.opfs=names}catch(e){r.opfs='n/a '+e}return JSON.stringify(r)})()`);
const probes = await ev(`(async()=>{const r={};for(const f of ['drift_worker.js','sqlite3.wasm']){const x=await fetch(f,{cache:'no-store'});r[f]={status:x.status,type:x.headers.get('content-type'),bytes:(await x.arrayBuffer()).byteLength}}return JSON.stringify(r)})()`);
const idb = await ev(`new Promise((res)=>{const q=indexedDB.open('axpert_pos');q.onerror=()=>res('open failed');q.onsuccess=async()=>{const db=q.result;const out={};for(const n of db.objectStoreNames){out[n]=await new Promise(r=>{const c=db.transaction(n).objectStore(n).count();c.onsuccess=()=>r(c.result);c.onerror=()=>r(-1)})}db.close();res(JSON.stringify(out))}})`);
// Drift's IndexedDB file system: store `files` {name,length} (key = file id) and
// store `blocks` (key [fileId, byteOffset], 4096-byte ArrayBuffers).
const dump = await ev(`new Promise((res)=>{const q=indexedDB.open('axpert_pos');q.onerror=()=>res(null);q.onsuccess=()=>{const db=q.result;const get=(n)=>new Promise(r=>{const rows=[];db.transaction(n).objectStore(n).openCursor().onsuccess=e=>{const c=e.target.result;if(!c){r(rows);return}rows.push([c.key,c.value]);c.continue()}});(async()=>{const files=await get('files');const blocks=await get('blocks');const b64=(buf)=>{let s='';const a=new Uint8Array(buf);for(let i=0;i<a.length;i++)s+=String.fromCharCode(a[i]);return btoa(s)};db.close();res(JSON.stringify({files:files.map(([k,v])=>({id:k,name:v.name,length:v.length})),blocks:blocks.map(([k,v])=>({file:k[0],offset:k[1],data:b64(v)}))}))})()}})`);
let row = null, rowProblem = null, settingsRows = null, markerRows = null, userVersion = null;
const tmp = `/tmp/drift_check_db_${port}.sqlite`;
try {
  const d = JSON.parse(dump);
  const file = d.files.find((f) => f.name === '/database');
  const parts = d.blocks.filter((b) => b.file === file.id).sort((a, b) => a.offset - b.offset);
  const bytes = Buffer.concat(parts.map((b) => Buffer.from(b.data, 'base64'))).subarray(0, file.length);
  if (bytes.subarray(0, 15).toString('latin1') !== 'SQLite format 3') throw new Error('not a SQLite file');
  fs.writeFileSync(tmp, bytes);
  const out = execFileSync('sqlite3', ['-readonly', '-json', tmp, 'SELECT singleton_id, device_id, outlet_id, register_id FROM device_context_entries'], { encoding: 'utf8' });
  row = JSON.parse(out || '[]');
  const q = (sql) => JSON.parse(execFileSync('sqlite3', ['-readonly', '-json', tmp, sql], { encoding: 'utf8' }) || '[]');
  settingsRows = q('SELECT key, value_json FROM settings ORDER BY key');
  markerRows = q("SELECT key, value FROM migration_state WHERE key = 'settings_copy_v1'");
  userVersion = q('PRAGMA user_version')[0]?.user_version;
} catch (e) { rowProblem = String(e).slice(0, 200); } finally { fs.rmSync(tmp, { force: true }); }
const uuidV4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
const rowOk = !!row && row.length === 1 && uuidV4.test(row[0].device_id);
const settingsOk = !!settingsRows && settingsRows.length === 5 && !!markerRows && markerRows.length === 1 && userVersion === 3;
const png = await send('Page.captureScreenshot', { format: 'png' });
fs.writeFileSync(`${outDir}/drift_check_${width}x${height}.png`, Buffer.from(png.data, 'base64'));
console.log('first Flutter view after', firstViewMs, 'ms');
console.log('responses:', JSON.stringify(responses));
console.log('storage:', storage);
console.log('probes:', probes);
console.log('indexedDB axpert_pos record counts:', idb);
console.log('device_context_entries row:', rowProblem ? 'NOT READ: ' + rowProblem : JSON.stringify(row), rowOk ? '(device_id is UUID v4; outlet_id/register_id may be null)' : '');
console.log('schema user_version:', userVersion, '| settings rows:', JSON.stringify(settingsRows));
console.log('settings_copy_v1 marker:', JSON.stringify(markerRows), settingsOk ? '(5 rows, marker present, v3)' : '(SETTINGS CHECK FAILED)');
console.log('console errors:', logs.length, logs.slice(0, 3).join(' | ').slice(0, 300));
const pr = JSON.parse(probes ?? '{}');
let stored = 0; try { stored = Object.values(JSON.parse(idb)).filter((n) => n > 0).reduce((a, b) => a + b, 0); } catch {}
const ok = ['drift_worker.js', 'sqlite3.wasm'].every((n) => pr[n]?.status === 200 && pr[n].bytes > 100000) && pr['sqlite3.wasm']?.type === 'application/wasm' && stored > 0 && rowOk && settingsOk && logs.length === 0;
console.log(ok ? 'DRIFT CHECK OK' : 'DRIFT CHECK FAILED');
ws.close(); proc.kill();
process.exit(ok ? 0 : 1);
