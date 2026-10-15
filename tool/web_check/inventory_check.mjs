// Inventory and payment-method check (DEC-148, DEC-149) against a served build or `flutter run`:
//   --dart-define=SKIP_ENTRY=true --dart-define=DEMO_SEED=true --dart-define=SKIP_ENTRY_USER=cashier1
//   node --experimental-websocket tool/web_check/inventory_check.mjs http://127.0.0.1:<port>/ <outDir> [width height]
// Scans one product, completes a cash sale (F2, Enter), then reads the database
// file rebuilt from IndexedDB: the product stock and the inventory balance
// dropped by one unit, an inventory `sale` row points at the sale, and the
// payment row's method_id is the store's `cash` row of payment_methods.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';


const [url, outDir = '/tmp/inventory_check', widthArg = '1280', heightArg = '720'] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
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
  const tmp = `/tmp/inventory_check_db_${port}.sqlite`;
  fs.writeFileSync(tmp, Buffer.concat(parts.map((b) => Buffer.from(b.data, 'base64'))).subarray(0, file.length));
  try { return sqls.map((s) => JSON.parse(execFileSync('sqlite3', ['-readonly', '-json', tmp, s], { encoding: 'utf8' }) || '[]')); }
  finally { fs.rmSync(tmp, { force: true }); }
}

const checks = [];
const check = (name, ok, detail = '') => { checks.push({ name, ok }); console.log(`${ok ? 'ok  ' : 'FAIL'} | ${name} ${detail}`); };

await load();
await shot('01_start');
const BARCODE = '8901234560011'; // Tata Tea, no offer on a single unit in this flow
const stockSql = `SELECT p.id, p.stock, b.quantity_milli, p.store_id FROM products p JOIN inventory_balance b ON b.product_id = p.id AND b.store_id = p.store_id WHERE p.barcode = '${BARCODE}' AND p.store_id = 'demo-store-ozone'`;
const [before, salesBefore, methodsBefore] = await query([stockSql, 'SELECT COUNT(*) n FROM sales', "SELECT store_id, COUNT(*) n FROM payment_methods GROUP BY store_id ORDER BY store_id"]);
check('seeded product has stock and an opening balance', before.length === 1 && before[0].quantity_milli === before[0].stock * 1000, JSON.stringify(before));
check('each demo store has four payment methods', methodsBefore.length === 2 && methodsBefore.every((m) => m.n === 4), JSON.stringify(methodsBefore));

await click(width / 2, 28);
await insert(BARCODE); await key('Enter', 13); await sleep(900);
await key('Escape', 27); await sleep(500);
await click(width / 2, 28);
await key('F2', 113); await sleep(700);
await key('Enter', 13); await sleep(2500);
await shot('02_receipt');
await sleep(2500);

const [salesAfter, after, saleRows, pay] = await query([
  'SELECT COUNT(*) n FROM sales',
  stockSql,
  `SELECT t.reason, t.quantity_delta_milli d, t.ref_type, t.ref_id, t.user_id, t.store_id FROM inventory_transactions t WHERE t.product_id = '${before[0]?.id}' AND t.reason = 'sale'`,
  "SELECT p.method, p.method_id, m.code, m.store_id m_store, s.store_id s_store FROM payments p JOIN sales s ON s.id = p.sale_id LEFT JOIN payment_methods m ON m.id = p.method_id ORDER BY p.created_at DESC LIMIT 1",
]);
check('one new sale was written', salesAfter[0].n === salesBefore[0].n + 1, `${salesBefore[0].n} -> ${salesAfter[0].n}`);
check('product stock dropped by one unit', after[0]?.stock === before[0].stock - 1, `${before[0].stock} -> ${after[0]?.stock}`);
check('inventory balance dropped by 1000 milli', after[0]?.quantity_milli === before[0].quantity_milli - 1000, `${before[0].quantity_milli} -> ${after[0]?.quantity_milli}`);
check('an inventory sale row points at the sale, with the user', saleRows.length === 1 && saleRows[0].d === -1000 && saleRows[0].ref_type === 'sale' && !!saleRows[0].ref_id && !!saleRows[0].user_id, JSON.stringify(saleRows));
check('the payment method came from the database (method_id -> cash row of the store)', pay.length === 1 && pay[0].method === 'cash' && pay[0].code === 'cash' && pay[0].m_store === pay[0].s_store, JSON.stringify(pay));
check('no console errors', logs.length === 0, logs.slice(0, 2).join(' | ').slice(0, 200));
const failed = checks.filter((c) => !c.ok);
console.log(`\n${checks.length} checks, ${failed.length} failed. Screenshots in ${outDir}`);
ws.close(); proc.kill();
process.exit(failed.length ? 1 : 0);
