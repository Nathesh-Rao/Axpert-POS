// Release-build check that the Drift web database really loads (DEC-117/119):
//   python3 tool/web_check/serve.py build/web 8300 &
//   node --experimental-websocket tool/web_check/drift_check.mjs http://127.0.0.1:8300/ <outDir> [width height] [--seed-duplicates]
// --seed-duplicates first writes two customers with the SAME id, the same member number and
// two sales whose customer names match 1 / 0 customers into localStorage (D2, KG-132) and
// expects the second to be imported as `<id>~dup2` with the report in the marker.
// Reports: HTTP status, size and content type of drift_worker.js and sqlite3.wasm
// (probed with fetch: the worker's own requests are not visible to the page),
// console errors, the browser storage the database created (IndexedDB names and
// OPFS entries), the device_context_entries row (read from a temp copy of the
// database file rebuilt from the IndexedDB blocks with the `sqlite3` CLI, then
// deleted), the settings rows, the settings_copy_v1 marker and user_version 7 (plus held_bills, products and sales with their markers)
// (D1 to D5) and the time until the first Flutter view. Exit 1 on a problem.
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import { execFileSync } from 'node:child_process';

const seedDuplicates = process.argv.includes('--seed-duplicates');
const [url, outDir = '/tmp/drift_check', widthArg = '1280', heightArg = '720'] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
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
if (seedDuplicates) {
  const cust = (id, name, member) => ({ id, name, phone: '9876543210', email: '', member, points: 10 });
  // Same shape as debug_check.mjs (a stored sale must parse, or the app does not start).
  const prod = { id: 0, name: 'Coca Cola 500ml', code: 'BDV001', barcode: '8901234567890', priceMinor: 4000, category: 'Beverages', sub: 'Soft Drinks', stock: 40, gst: 18, image: 0, favourite: false };
  const sale = (n, customer) => ({
    number: 'AX' + String(n).padStart(6, '0'), date: new Date().toISOString(), store: 'Maison Galaxy', customer,
    cart: { lines: [{ product: prod, qtyMilli: 1000, priceMinor: 4000, discountBp: 0 }], customer: 'walk', saleType: 'Cash', discountType: 'percent', billDiscountBp: 0, billDiscountMinor: 0, reason: '', points: 0, note: '' },
    totals: { items: 1, qtyMilli: 1000, valueMinor: 4000, subtotalMinor: 4000, discountMinor: 0, taxMinor: 0, pointsMinor: 0, totalMinor: 4000 },
    mode: 'Cash', tenderedMinor: 4000, changeMinor: 0, returned: {},
  });
  const held = (ref, qtyMilli) => ({ ref, time: '2026-10-12T10:00:00.000Z', cart: { lines: [{ product: prod, qtyMilli, priceMinor: 4000, discountBp: 0 }], customer: 'walk', saleType: 'Cash', discountType: 'percent', billDiscountBp: 0, billDiscountMinor: 0, reason: '', points: 0, note: '' } });
  const seed = {
    'flutter.axpert-customers': JSON.stringify(JSON.stringify([cust('walk', 'Walk-in Customer', ''), cust('7', 'Asha', 'MG00007'), cust('7', 'Bela', 'MG00007')])),
    'flutter.axpert-sales': JSON.stringify(JSON.stringify([sale(1, 'Asha'), sale(2, 'Nobody'), sale(1, 'Asha')])),
    // D3: two held bills with the SAME ref (KG-125), both must be imported unchanged.
    // D4: three products, two share a code (case-insensitive) and two a barcode: all imported, reported.
    'flutter.axpert-products': JSON.stringify(JSON.stringify([0, 1, 2].map((i) => ({ id: i, name: 'Dup ' + i, code: ['DUP1', 'dup1', 'OTHER'][i], barcode: ['111', '222', '111'][i], priceMinor: 1000 + i, category: 'Snacks', sub: 'Chips', stock: 5 + i, gst: [18, 5.5, 0][i], image: -1, favourite: i === 1 })))),
    'flutter.axpert-held': JSON.stringify(JSON.stringify([held('H111111', 1000), held('H111111', 2000), held('H222222', 3000)])),
  };
  await send('Page.addScriptToEvaluateOnNewDocument', { source: `try{if(!localStorage.getItem('flutter.axpert-customers')){const d=${JSON.stringify(seed)};for(const k in d)localStorage.setItem(k,d[k])}}catch(e){}` });
}
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
let row = null, rowProblem = null, settingsRows = null, markerRows = null, userVersion = null, customerRows = null, customersMarker = null, heldRows = null, heldMarker = null, productRows = null, productsMarker = null, saleRows = null, saleLineRows = null, salesMarker = null, paymentCount = null;
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
  customerRows = q('SELECT id, legacy_id, position, name, member_no, points, deleted_at, server_id, server_version, device_id FROM customers ORDER BY position');
  customersMarker = q("SELECT value FROM migration_state WHERE key = 'customers_copy_v1'");
  heldRows = q('SELECT id, ref, position, held_at, cart_json, deleted_at FROM held_bills ORDER BY position');
  heldMarker = q("SELECT value FROM migration_state WHERE key = 'held_copy_v1'");
  productRows = q('SELECT id, legacy_id, position, name, code, barcode, price_minor, currency_code, stock, gst_bp, favourite, deleted_at, server_id, server_version, device_id FROM products ORDER BY position');
  productsMarker = q("SELECT value FROM migration_state WHERE key = 'products_copy_v1'");
  saleRows = q('SELECT id, has_sale_id, number, position, customer_legacy_id, customer_id, total_minor, returned_order, deleted_at, server_id, server_version, device_id FROM sales ORDER BY position');
  saleLineRows = q('SELECT sale_id, line_no, product_legacy_id, product_name, product_gst_bp, qty_milli, returned_qty_milli FROM sale_lines ORDER BY sale_id, line_no');
  salesMarker = q("SELECT value FROM migration_state WHERE key = 'sales_copy_v1'");
  paymentCount = q('SELECT COUNT(*) AS n FROM payments')[0]?.n;
  userVersion = q('PRAGMA user_version')[0]?.user_version;
} catch (e) { rowProblem = String(e).slice(0, 200); } finally { fs.rmSync(tmp, { force: true }); }
const uuidV4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
const rowOk = !!row && row.length === 1 && uuidV4.test(row[0].device_id);
const settingsOk = !!settingsRows && settingsRows.length === 5 && !!markerRows && markerRows.length === 1 && userVersion === 7;
const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
const report = customersMarker?.length === 1 ? JSON.parse(JSON.parse(customersMarker[0].value).report ? customersMarker[0].value : '{}').report : null;
const customersOk = !!customerRows && customersMarker?.length === 1 && customerRows.every((r, i) => uuidRe.test(r.id) && r.position === i && !r.deleted_at && r.server_id === null && r.server_version === null && r.device_id === null)
  && (seedDuplicates
    ? customerRows.map((r) => r.legacy_id).join(',') === 'walk,7,7~dup2' && customerRows[2].name === 'Bela' && report?.renamed?.length === 1 && report.renamed[0].to === '7~dup2' && Object.keys(report.duplicate_members).join() === 'MG00007' && report.sales_checked === 3 && report.sales_name_unmatched === 1
    : customerRows.map((r) => r.legacy_id).join(',') === 'walk,1,2,3' && report?.renamed?.length === 0);
const heldReport = heldMarker?.length === 1 ? JSON.parse(heldMarker[0].value) : null;
const heldOk = !!heldRows && heldMarker?.length === 1 && heldRows.every((r, i) => uuidRe.test(r.id) && r.position === i && !r.deleted_at)
  && (seedDuplicates
    ? heldRows.map((r) => r.ref).join(',') === 'H111111,H111111,H222222' && heldRows.map((r) => JSON.parse(r.cart_json).lines[0].qtyMilli).join(',') === '1000,2000,3000' && heldReport.count === 3 && heldReport.report?.duplicate_refs?.H111111 === 2
    : heldRows.length === 0 && heldReport.count === 0);
const productsReport = productsMarker?.length === 1 ? JSON.parse(productsMarker[0].value) : null;
const productsOk = !!productRows && productsMarker?.length === 1 && productRows.every((r, i) => uuidRe.test(r.id) && r.position === i && r.legacy_id === i && !r.deleted_at && r.currency_code === 'INR' && r.server_id === null && r.server_version === null && r.device_id === null)
  && (seedDuplicates
    ? productRows.length === 3 && productsReport.count === 3 && productRows.map((r) => r.gst_bp).join(',') === '1800,550,0' && productRows[1].favourite === 1 && productRows[2].stock === 7 && JSON.stringify(productsReport.report.duplicate_codes) === '{"dup1":[0,1]}' && JSON.stringify(productsReport.report.duplicate_barcodes) === '{"111":[0,2]}'
    : productRows.length === 20 && productsReport.count === 20);
const salesReport = salesMarker?.length === 1 ? JSON.parse(salesMarker[0].value) : null;
const salesOk = !!saleRows && salesMarker?.length === 1 && paymentCount === 0 && saleRows.every((r, i) => uuidRe.test(r.id) && r.position === i && !r.deleted_at && r.server_id === null && r.server_version === null && r.device_id === null && r.returned_order === '[]')
  && (seedDuplicates
    ? saleRows.length === 3 && saleRows.every((r) => r.has_sale_id === 0) && new Set(saleRows.map((r) => r.id)).size === 3 && saleRows.map((r) => r.number).join() === 'AX000001,AX000002,AX000001' && saleLineRows.length === 3 && saleLineRows.every((l) => l.product_name === 'Coca Cola 500ml' && l.product_gst_bp === 1800 && l.qty_milli === 1000) && salesReport.count === 3 && salesReport.report?.duplicate_numbers?.AX000001 === 2 && salesReport.report?.legacy_without_sale_id === 3
    : saleRows.length === 0 && salesReport.count === 0);
const png = await send('Page.captureScreenshot', { format: 'png' });
fs.writeFileSync(`${outDir}/drift_check_${width}x${height}.png`, Buffer.from(png.data, 'base64'));
console.log('first Flutter view after', firstViewMs, 'ms');
console.log('responses:', JSON.stringify(responses));
console.log('storage:', storage);
console.log('probes:', probes);
console.log('indexedDB axpert_pos record counts:', idb);
console.log('device_context_entries row:', rowProblem ? 'NOT READ: ' + rowProblem : JSON.stringify(row), rowOk ? '(device_id is UUID v4; outlet_id/register_id may be null)' : '');
console.log('schema user_version:', userVersion, '| settings rows:', JSON.stringify(settingsRows));
console.log('customers rows:', JSON.stringify(customerRows?.map((r) => `${r.position}:${r.legacy_id}:${r.name}:${r.points}`)), '| customers_copy_v1 marker:', customersMarker?.length === 1 ? customersMarker[0].value.slice(0, 400) : 'MISSING', customersOk ? '(customers OK)' : '(CUSTOMERS CHECK FAILED)');
console.log('held_bills rows:', JSON.stringify(heldRows?.map((r) => `${r.position}:${r.ref}`)), '| held_copy_v1 marker:', heldMarker?.length === 1 ? heldMarker[0].value.slice(0, 200) : 'MISSING', heldOk ? '(held OK)' : '(HELD CHECK FAILED)');
console.log('products rows:', JSON.stringify(productRows?.map((r) => `${r.position}:${r.legacy_id}:${r.code}:${r.stock}:${r.gst_bp}`).slice(0, 5)), `(${productRows?.length} rows)`, '| products_copy_v1 marker:', productsMarker?.length === 1 ? productsMarker[0].value.slice(0, 300) : 'MISSING', productsOk ? '(products OK)' : '(PRODUCTS CHECK FAILED)');
console.log('sales rows:', JSON.stringify(saleRows?.map((r) => `${r.position}:${r.number}:${r.has_sale_id}:${r.customer_id ? 'linked' : 'unlinked'}`)), `(${saleLineRows?.length} lines, ${paymentCount} payments)`, '| sales_copy_v1 marker:', salesMarker?.length === 1 ? salesMarker[0].value.slice(0, 300) : 'MISSING', salesOk ? '(sales OK)' : '(SALES CHECK FAILED)');
console.log('settings_copy_v1 marker:', JSON.stringify(markerRows), settingsOk ? '(5 rows, marker present, v7)' : '(SETTINGS CHECK FAILED)');
console.log('console errors:', logs.length, logs.slice(0, 3).join(' | ').slice(0, 300));
const pr = JSON.parse(probes ?? '{}');
let stored = 0; try { stored = Object.values(JSON.parse(idb)).filter((n) => n > 0).reduce((a, b) => a + b, 0); } catch {}
const ok = ['drift_worker.js', 'sqlite3.wasm'].every((n) => pr[n]?.status === 200 && pr[n].bytes > 100000) && pr['sqlite3.wasm']?.type === 'application/wasm' && stored > 0 && rowOk && settingsOk && customersOk && heldOk && productsOk && salesOk && logs.length === 0;
console.log(ok ? 'DRIFT CHECK OK' : 'DRIFT CHECK FAILED');
ws.close(); proc.kill();
process.exit(ok ? 0 : 1);
