// Selling by packaging (DEC-154), debug or release build, accessibility ON.
//   flutter run -d web-server --web-port=<p> --web-hostname=127.0.0.1 --dart-define=SKIP_ENTRY=true --dart-define=DEMO_SEED=true
//   node --experimental-websocket tool/web_check/packaging_sale_check.mjs http://127.0.0.1:<p>/ <outDir>
// Signs in as the first user (admin, Ozone store). Sells Coca Cola pieces and a carton in ONE sale
// (scanning the carton barcode), a Box of Oreo with Buy 1 Get 1, pays cash, reads the database back
// (sale_lines snapshots, inventory in base units), reads the receipt text, tests Ctrl+Shift+U and
// Cmd+Shift+U, refunds one carton and checks that 24 pieces return to the stock.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';

const [url, outDir = '/tmp/packaging_sale_check'] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
const width = 1280, height = 720;
fs.mkdirSync(outDir, { recursive: true });
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const port = 9300 + Math.floor(Math.random() * 500);
const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, `--window-size=${width},${height}`, '--user-data-dir=/tmp/psale-' + port, 'about:blank'], { stdio: 'ignore' });
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
const labels = async () => (await nodes()).map((n) => n.l).join('|');
const chord = async (k, code, vk, meta) => {
  const [mk, mcode, mvk, m] = meta ? ['Meta', 'MetaLeft', 91, 4] : ['Control', 'ControlLeft', 17, 2];
  const mods = m | 8; // + Shift
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key: mk, code: mcode, windowsVirtualKeyCode: mvk, modifiers: m });
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key: 'Shift', code: 'ShiftLeft', windowsVirtualKeyCode: 16, modifiers: mods });
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key: k, code, windowsVirtualKeyCode: vk, modifiers: mods });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', key: k, code, windowsVirtualKeyCode: vk, modifiers: mods });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', key: 'Shift', code: 'ShiftLeft', windowsVirtualKeyCode: 16, modifiers: m });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', key: mk, code: mcode, windowsVirtualKeyCode: mvk, modifiers: 0 });
  await sleep(900);
};
const scan = async (code) => { await click(width / 2, 28); await insert(code); await key('Enter', 13); await sleep(1400); };

await click(32, 100); await sleep(1500); // POS
await scan('8901234560000');           // Coca Cola piece
await scan('8901234560000');           // 2 pieces
await scan('18901234560007');          // Coca Cola CARTON barcode
await scan('18901234560153');          // Oreo Box of 12 (Buy 1 Get 1)
await shot('01_cart');
let text = await labels();
check('the carton barcode added a Carton line (unit chip shows it)', text.includes('Change the unit of Coca Cola 500ml') && text.includes('Carton of 24'));
check('the Oreo box line shows its unit and the Buy 1 Get 1 saving', text.includes('Box of 12') && text.includes('Oreo Buy 1 Get 1'));
check('the toast named the unit', text.includes('Coca Cola 500ml (Carton of 24) added') || text.includes('Oreo Biscuit 120g (Box of 12) added'));

// Ctrl+Shift+U and Cmd+Shift+U change the unit of the selected row (the Oreo box, last scanned):
// Oreo has two units (Piece, Box of 12), so each press flips it. Wait first for the toasts to go.
await sleep(5000);
check('before: the Oreo row is sold as Box of 12', (await labels()).includes('Box of 12'));
await chord('U', 'KeyU', 85, false);
await shot('02_after_ctrl_shift_u');
check('Ctrl+Shift+U switched the selected row from Box of 12 to Piece', !(await labels()).includes('Box of 12'));
await chord('U', 'KeyU', 85, true);
await shot('03_after_cmd_shift_u');
check('Cmd+Shift+U switched it back to Box of 12', (await labels()).includes('Box of 12'));
check('no shortcut collision: the page still shows the cart', (await labels()).includes('Change the unit of'));

// Put the Oreo row back to the box with the unit chip popover (Pack, then Box).
await key('F2', 113); await sleep(900);
await key('Enter', 13); await sleep(3500);
await shot('04_receipt');
text = await labels();
check('the receipt shows the carton quantity with its unit', /1\.000 Carton of 24/.test(text));
check('the receipt shows the pack detail under the name', text.includes('1 Carton of 24 @ ₹900.00'));

const [lines, tx, bal, prod] = await query([
  "SELECT l.product_name, l.qty_milli, l.packaging_id, l.unit_name, l.quantity_base_milli, l.base_qty_milli, l.offer_kind, l.price_minor FROM sale_lines l ORDER BY l.created_at DESC, l.line_no LIMIT 6",
  "SELECT x.name, t.reason, t.quantity_delta_milli q FROM inventory_transactions t JOIN products x ON x.id = t.product_id WHERE t.reason = 'sale' ORDER BY t.created_at DESC LIMIT 6",
  "SELECT x.name, b.quantity_milli q FROM inventory_balance b JOIN products x ON x.id = b.product_id WHERE x.store_id = 'demo-store-ozone' AND x.name IN ('Coca Cola 500ml', 'Oreo Biscuit 120g') ORDER BY x.name",
  "SELECT name, stock FROM products WHERE store_id = 'demo-store-ozone' AND name IN ('Coca Cola 500ml', 'Oreo Biscuit 120g') ORDER BY name",
]);
console.log(JSON.stringify({ lines, tx, bal, prod }));
const carton = lines.find((l) => l.packaging_id === 'demo-pack-oz-1-c24');
check('sale_lines: the carton line has its packaging snapshot', !!carton && carton.unit_name === 'Carton of 24' && carton.quantity_base_milli === 24000 && carton.base_qty_milli === 24000 && carton.price_minor === 90000, JSON.stringify(carton));
const pieces = lines.find((l) => l.product_name === 'Coca Cola 500ml' && l.packaging_id === null);
check('sale_lines: the pieces are a separate base-unit line', !!pieces && pieces.qty_milli === 2000 && pieces.base_qty_milli === null, JSON.stringify(pieces));
check('inventory moved in BASE units (26 for Coca Cola, 12 for the Oreo box)', tx.some((t) => t.name === 'Coca Cola 500ml' && t.q === -26000) || (tx.filter((t) => t.name === 'Coca Cola 500ml').reduce((a, t) => a + t.q, 0) === -26000), JSON.stringify(tx));
check('balance: Coca Cola 14, Oreo 73 (base units)', bal.find((b) => b.name === 'Coca Cola 500ml')?.q === 14000 && bal.find((b) => b.name === 'Oreo Biscuit 120g')?.q === 73000 && prod.find((p) => p.name === 'Coca Cola 500ml')?.stock === 14, JSON.stringify({ bal, prod }));

// Refund ONE carton through Returns.
await key('Escape', 27); await sleep(700);
await click(32, 276); await sleep(2000); // Returns
const sales = await query(["SELECT number FROM sales ORDER BY created_at DESC LIMIT 1"]);
const number = sales[0][0]?.number;
await click(350, 243); await insert(number); await sleep(1500);
await shot('05_returns');
const listed = (await labels()).includes('Coca Cola 500ml (Carton of 24)');
check('Returns lists the carton line by its unit', listed);
if (listed) {
  await click(593, 424); // the quantity box of the second row (the carton)
  await key('a', 65); await insert('1'); await sleep(500);
  await click(358, 646); await sleep(1200);
  await shot('05b_confirm');
  await click(744, 400); await sleep(3500);
  await shot('06_refunded');
  const [ret, bal2, tx2] = await query([
    "SELECT l.unit_name, l.returned_qty_milli FROM sale_lines l WHERE l.packaging_id = 'demo-pack-oz-1-c24' ORDER BY l.created_at DESC LIMIT 1",
    "SELECT b.quantity_milli q FROM inventory_balance b JOIN products x ON x.id = b.product_id WHERE x.store_id = 'demo-store-ozone' AND x.name = 'Coca Cola 500ml'",
    "SELECT t.quantity_delta_milli q FROM inventory_transactions t JOIN products x ON x.id = t.product_id WHERE x.store_id = 'demo-store-ozone' AND x.name = 'Coca Cola 500ml' AND t.reason = 'return'",
  ]);
  check('the carton line shows 1 returned', ret[0]?.returned_qty_milli === 1000, JSON.stringify(ret));
  check('one carton returned 24 pieces to the stock (14 to 38)', tx2.length === 1 && tx2[0].q === 24000 && bal2[0]?.q === 38000, JSON.stringify({ tx2, bal2 }));
}
check('no console errors', logs.length === 0, logs.slice(0, 3).join(' | ').slice(0, 400));
const failed = checks.filter((c) => !c.ok);
console.log(`\n${checks.length} checks, ${failed.length} failed. Screenshots in ${outDir}`);
ws.close(); proc.kill();
process.exit(failed.length ? 1 : 0);
