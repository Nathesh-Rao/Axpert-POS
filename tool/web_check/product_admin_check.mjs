// Product management click-through (DEC-152, DEC-153), debug or release build,
// accessibility ON (the form is driven through its semantics labels).
//   flutter run -d web-server --web-port=<p> --web-hostname=127.0.0.1 --dart-define=SKIP_ENTRY=true --dart-define=DEMO_SEED=true
//   node --experimental-websocket tool/web_check/product_admin_check.mjs http://127.0.0.1:<p>/ <outDir> --admin
//   (admin: signs in as the first user, Demo#Admin1: creates a product with a
//    24-piece carton and opening stock, adds Buy 1 Get 1, checks the tile
//    badge, sells one, reads the database rows back.)
//   With --cashier the app must run WITHOUT SKIP_ENTRY_USER=admin... use
//   --dart-define=SKIP_ENTRY_USER=cashier1: no add or edit controls.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';

const cashier = process.argv.includes('--cashier');
const [url, outDir = '/tmp/product_admin_check'] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
const width = 1280, height = 720;
fs.mkdirSync(outDir, { recursive: true });
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const port = 9300 + Math.floor(Math.random() * 500);
const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, `--window-size=${width},${height}`, '--user-data-dir=/tmp/padmin-' + port, 'about:blank'], { stdio: 'ignore' });
let targets;
for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {} await sleep(200); }
const ws = new WebSocket(targets.find((t) => t.type === 'page').webSocketDebuggerUrl);
await new Promise((r) => (ws.onopen = r));
let id = 0; const pending = new Map(); const logs = [];
const BAD = /setState\(\) or markNeedsBuild|EXCEPTION CAUGHT|Another exception was thrown|RenderFlex overflowed|TextEditingController was used after being disposed/;
ws.onmessage = (m) => {
  const d = JSON.parse(m.data);
  if (d.id && pending.has(d.id)) { pending.get(d.id)(d.result); pending.delete(d.id); }
  else if (d.method === 'Runtime.consoleAPICalled') {
    const text = d.params.args.map((a) => a.value ?? a.description).join(' ');
    if (['error', 'assert'].includes(d.params.type) || BAD.test(text)) logs.push(text);
  }
  else if (d.method === 'Runtime.exceptionThrown') logs.push('EXCEPTION ' + (d.params.exceptionDetails.exception?.description ?? d.params.exceptionDetails.text));
  else if (d.method === 'Log.entryAdded' && d.params.entry.level === 'error') logs.push(d.params.entry.text + ' ' + (d.params.entry.url ?? ''));
};
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
const ev = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true })).result?.value;
await send('Runtime.enable'); await send('Log.enable'); await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
const click = async (x, y) => { await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y }); await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 }); await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 }); await sleep(450); };
const insert = async (text) => { await send('Input.insertText', { text }); await sleep(250); };
const key = async (k, vk) => { await send('Input.dispatchKeyEvent', { type: 'keyDown', key: k, code: k, windowsVirtualKeyCode: vk }); await send('Input.dispatchKeyEvent', { type: 'keyUp', key: k, code: k, windowsVirtualKeyCode: vk }); await sleep(350); };
const wheel = async (dy) => { await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 640, y: 400, deltaX: 0, deltaY: dy }); await sleep(500); };
const shot = async (name) => { const r = await send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync(`${outDir}/${name}.png`, Buffer.from(r.data, 'base64')); };
const checks = [];
const check = (name, ok, detail = '') => { checks.push({ name, ok }); console.log(`${ok ? 'ok  ' : 'FAIL'} | ${name} ${detail}`); };

const nodes = async () => JSON.parse(await ev("JSON.stringify([...document.querySelectorAll('flt-semantics')].map(n=>{const r=n.getBoundingClientRect();return {l:(n.getAttribute('aria-label')||n.textContent||'').trim(),x:r.x,y:r.y,w:r.width,h:r.height}}).filter(a=>a.l&&a.w>0))"));
// A node whose label is `label` (or starts with it, for buttons: "Label\nLabel").
const find = async (label, nth = 0, exact = true) => {
  const m = (await nodes()).filter((n) => (exact ? n.l === label || n.l === `${label}\n${label}` : n.l.startsWith(label)));
  return m[nth < 0 ? m.length + nth : nth] ?? null;
};
// Scrolls the dialog until the node sits inside the window, then returns it.
const reveal = async (label, nth = 0, exact = true) => {
  for (let i = 0; i < 12; i++) {
    const n = await find(label, nth, exact);
    if (!n) { await sleep(300); continue; }
    if (n.y + n.h > 80 && n.y + n.h < height - 40) return n;
    await wheel(n.y > height / 2 ? 250 : -250);
  }
  return await find(label, nth, exact);
};
const press = async (label, nth = 0, exact = true) => { const n = await reveal(label, nth, exact); if (!n) { check(`found "${label}"`, false); return false; } await click(n.x + n.w / 2, n.y + n.h / 2); return true; };
// The text box under a label.
const fillBelow = async (label, text, nth = 0) => { const n = await reveal(label, nth); if (!n) { check(`found field "${label}"`, false); return; } await click(n.x + 60, n.y + n.h + 22); await insert(text); };

const [db, dbFile] = [null, null];
async function query(sqls) {
  const dump = await ev(`new Promise((res)=>{const q=indexedDB.open('axpert_pos');q.onerror=()=>res(null);q.onsuccess=()=>{const db=q.result;const get=(n)=>new Promise(r=>{const rows=[];db.transaction(n).objectStore(n).openCursor().onsuccess=e=>{const c=e.target.result;if(!c){r(rows);return}rows.push([c.key,c.value]);c.continue()}});(async()=>{const files=await get('files');const blocks=await get('blocks');const b64=(buf)=>{let s='';const a=new Uint8Array(buf);for(let i=0;i<a.length;i++)s+=String.fromCharCode(a[i]);return btoa(s)};db.close();res(JSON.stringify({files:files.map(([k,v])=>({id:k,name:v.name,length:v.length})),blocks:blocks.map(([k,v])=>({file:k[0],offset:k[1],data:b64(v)}))}))})()}})`);
  const d = JSON.parse(dump);
  const file = d.files.find((f) => f.name === '/database');
  const parts = d.blocks.filter((b) => b.file === file.id).sort((a, b) => a.offset - b.offset);
  const tmp = `/tmp/padmin_db_${port}.sqlite`;
  fs.writeFileSync(tmp, Buffer.concat(parts.map((b) => Buffer.from(b.data, 'base64'))).subarray(0, file.length));
  try { return sqls.map((s) => JSON.parse(execFileSync('sqlite3', ['-readonly', '-json', tmp, s], { encoding: 'utf8' }) || '[]')); }
  finally { fs.rmSync(tmp, { force: true }); }
}

await send('Page.navigate', { url });
for (let i = 0; i < 300; i++) { if (await ev("!!document.querySelector('flutter-view, flt-glass-pane')")) break; await sleep(200); }
await sleep(9000);
await ev("(()=>{const p=document.querySelector('flt-semantics-placeholder'); if(p) p.click()})()");
await sleep(2500);
await click(32, 144); // Products
await sleep(2000);
await shot('01_products');

if (cashier) {
  const all = (await nodes()).map((n) => n.l).join('|');
  check('cashier: no Add product', !all.includes('Add product'));
  check('cashier: no Edit / Deactivate / Actions', !/(^|\|)Edit(\n|\|)/.test(all) && !all.includes('Deactivate') && !all.includes('Actions'));
  check('cashier: no Show inactive', !all.includes('Show inactive'));
  await key('i', 73); // Cmd/Ctrl+I is not sent: plain I must do nothing
  check('cashier: the table is still there', all.includes('Coca Cola 500ml'));
} else {
  await press('Add product', 0, false);
  await sleep(1500);
  await shot('02_form_open');
  await fillBelow('Name', 'Check Cola');
  await fillBelow('SKU', 'CHK001', 0);
  await fillBelow('Base price (INR)', '100');
  // The tax slab is a required choice (nothing preselected): pick the first slab.
  await press('Select rate', 0, false);
  await sleep(500);
  await press('18%');
  await sleep(400);
  await fillBelow('Barcodes (base unit)', '9990001112223');
  await key('Enter', 13);
  await press('Add packaging', 0, false);
  await sleep(800);
  if (process.env.PROBE) { await wheel(300); await shot('probe'); console.log((await nodes()).map((n) => `${n.l.replace(/\n/g, '/')}@${Math.round(n.x)},${Math.round(n.y)}`).join('\n')); proc.kill(); process.exit(0); }
  await press('Unit\nBox', 0, false);
  await sleep(600);
  await shot('03_unit_list');
  await press('Carton');
  await sleep(500);
  await fillBelow('Contains (Piece)', '24');
  await fillBelow('Barcode', '9990001112224', 0);
  const preview = (await nodes()).map((n) => n.l).find((l) => l.startsWith('1 Carton = 24 Piece')) ?? '';
  check('packaging preview shows 1 Carton = 24 Piece = ₹2,400.00', preview.includes('₹2,400.00'), preview);
  await shot('04_packaging');
  // Opening stock: 3 cartons + 5 pieces = 77.
  await fillBelow('Opening stock', '3');
  const unit = await find('Carton +');
  await click(unit.x + unit.w + 50, unit.y + unit.h / 2);
  await insert('5');
  const total = (await nodes()).map((n) => n.l).find((l) => l.startsWith('= ')) ?? '';
  check('opening stock total is 77 Piece', total.includes('77'), total);
  // Buy 1 Get 1.
  await press('Add offer', 0);
  await sleep(600);
  await press('Type\nDiscount', 0, false);
  await sleep(500);
  await press('Promotion');
  await sleep(500);
  const prev = (await nodes()).map((n) => n.l).join('|');
  check('offer preview shows the Buy 1 Get 1 badge and half price', prev.includes('Buy 1 Get 1') && prev.includes('₹100.00 to ₹50.00'));
  await shot('05_offer');
  await press('Add offer', -1);
  await sleep(600);
  await shot('06_offer_added');
  await press('Create product', 0);
  await sleep(3500);
  await shot('07_after_save');
  await click(300, 205); await insert('Check Cola'); await sleep(1500);
  await shot('07b_filtered');
  const afterSave = (await nodes()).map((n) => n.l).join('|');
  check('the form closed and the product is in the table', !afterSave.includes('Create product') && afterSave.includes('Check Cola'));
  check('the stock cell reads 3 Carton + 5 Piece', afterSave.includes('3 Carton + 5 Piece'));
  check('the stock chip keeps the whole units (77)', afterSave.includes('77'));
  // POS: the tile has the Buy 1 Get 1 badge.
  await click(32, 100);
  await sleep(2500);
  await click(490, 240);
  await insert('Check Cola');
  await sleep(1500);
  await shot('08_pos_search');
  const pos = (await nodes()).map((n) => n.l).join('|');
  check('the sales tile shows Check Cola with Buy 1 Get 1', pos.includes('Check Cola') && pos.includes('Buy 1 Get 1'));
  // Sell one by its base barcode: clear the search, scan, pay cash.
  await click(width / 2, 28);
  await insert('9990001112223');
  await key('Enter', 13);
  await sleep(1500);
  await shot('08b_cart');
  await key('F2', 113); await sleep(800);
  await key('Enter', 13); await sleep(3000);
  await shot('09_receipt');
  const [prod, pack, codes, ledger, bal, off, lines, cat] = await query([
    "SELECT id, name, code, barcode, price_minor, stock, store_id, deleted_at FROM products WHERE code = 'CHK001'",
    "SELECT p.name, p.quantity_base_milli, p.enabled, p.price_minor FROM product_packagings p JOIN products x ON x.id = p.product_id WHERE x.code = 'CHK001' AND p.deleted_at IS NULL",
    "SELECT b.barcode, b.packaging_id IS NULL AS base FROM product_barcodes b JOIN products x ON x.id = b.product_id WHERE x.code = 'CHK001' AND b.deleted_at IS NULL ORDER BY base DESC",
    "SELECT t.reason, t.quantity_delta_milli q FROM inventory_transactions t JOIN products x ON x.id = t.product_id WHERE x.code = 'CHK001' ORDER BY t.created_at",
    "SELECT quantity_milli FROM inventory_balance b JOIN products x ON x.id = b.product_id WHERE x.code = 'CHK001'",
    "SELECT o.kind, o.percent_bp, o.active FROM offers o JOIN products x ON x.id = o.product_id WHERE x.code = 'CHK001' AND o.deleted_at IS NULL",
    "SELECT l.product_name, l.qty_milli, l.offer_kind, l.discount_bp FROM sale_lines l WHERE l.product_name = 'Check Cola'",
    "SELECT COUNT(*) n FROM seed_manifest WHERE row_id IN (SELECT id FROM products WHERE code = 'CHK001')",
  ]);
  console.log(JSON.stringify({ prod, pack, codes, ledger, bal, off, lines, cat }));
  check('product row: price 10000, active, store stamped', prod.length === 1 && prod[0].price_minor === 10000 && prod[0].deleted_at === null && prod[0].store_id === 'demo-store-ozone');
  check('packaging row: Carton, 24000 milli, derived price', pack.length === 1 && pack[0].name === 'Carton' && pack[0].quantity_base_milli === 24000 && pack[0].price_minor === null);
  check('barcode rows: base and carton', codes.length === 2 && codes[0].barcode === '9990001112223' && codes[1].barcode === '9990001112224');
  check('ledger: opening 77000, then the sale -1000', ledger.length === 2 && ledger[0].reason === 'opening' && ledger[0].q === 77000 && ledger[1].reason === 'sale' && ledger[1].q === -1000, JSON.stringify(ledger));
  check('balance 76000 and products.stock 76', bal[0]?.quantity_milli === 76000 && prod[0]?.stock === 76);
  check('offer row: promotion 5000 bp, active', off.length === 1 && off[0].kind === 'promotion' && off[0].percent_bp === 5000 && off[0].active === 1);
  check('the sale line has the Buy 1 Get 1 offer', lines.length === 1 && lines[0].offer_kind === 'promotion');
  check('the product is not in seed_manifest', cat[0].n === 0);
}
check('no console errors', logs.length === 0, logs.slice(0, 3).join(' | ').slice(0, 400));
const failed = checks.filter((c) => !c.ok);
console.log(`\n${checks.length} checks, ${failed.length} failed. Screenshots in ${outDir}`);
ws.close(); proc.kill();
process.exit(failed.length ? 1 : 0);
