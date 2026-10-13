// Release-build check of the DB-driven demo (DEC-132 to DEC-135).
//   flutter build web --release --dart-define=SKIP_ENTRY=true --dart-define=DEMO_SEED=true --dart-define=SKIP_ENTRY_USER=cashier1|cashier2
//   python3 tool/web_check/serve.py build/web 8310 &
//   node --experimental-websocket tool/web_check/demo_check.mjs http://127.0.0.1:8310/ <outDir> --store=ozone|kampala [width height]
// ozone: the seed ran once (row counts), a reload keeps the data and does not
//   seed again, the offers show on the tiles (screenshot), a checkout with an
//   offer and an unlocked free item writes a stamped sale (read from the
//   database file rebuilt from IndexedDB).
// kampala (built with SKIP_ENTRY_USER=cashier2): the second store shows its own
//   currency (read from the accessibility text) and no rupee sign, VAT text
//   everywhere (summary and receipt) and no GST/CGST/SGST, its own forex list.
// ozone also checks GST, the CGST/SGST rows and the forex selector with rates.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';

const store = (process.argv.find((a) => a.startsWith('--store=')) ?? '--store=ozone').split('=')[1];
const [url, outDir = '/tmp/demo_check', widthArg = '1280', heightArg = '720'] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
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
  const tmp = `/tmp/demo_check_db_${port}.sqlite`;
  fs.writeFileSync(tmp, Buffer.concat(parts.map((b) => Buffer.from(b.data, 'base64'))).subarray(0, file.length));
  try { return sqls.map((s) => JSON.parse(execFileSync('sqlite3', ['-readonly', '-json', tmp, s], { encoding: 'utf8' }) || '[]')); }
  finally { fs.rmSync(tmp, { force: true }); }
}

// Opens the forex selector (found by its accessibility label) and returns the
// semantics text with the open list.
const openForex = async () => {
  const box = await ev("(()=>{const m=[...document.querySelectorAll('flt-semantics')].filter(n=>((n.getAttribute('aria-label')||n.textContent||'').trim()==='USD'));const rs=m.map(n=>n.getBoundingClientRect()).filter(r=>r.width>0);if(!rs.length)return null;const r=rs.sort((a,b)=>b.x-a.x)[0];return {x:r.x+r.width/2,y:r.y+r.height/2}})()");
  if (!box) return '';
  await click(width * 0.89, box.y); await sleep(900);
  return await ev('document.body.innerHTML');
};
const checks = [];
const check = (name, ok, detail = '') => { checks.push({ name, ok }); console.log(`${ok ? 'ok  ' : 'FAIL'} | ${name} ${detail}`); };

await load();
await shot(`${store}_01_start`);
if (store === 'ozone') {
  const counts = (r) => Object.fromEntries(r.map((x) => [x.t, x.n]));
  const countSql = "SELECT 'stores' t, COUNT(*) n FROM stores UNION ALL SELECT 'products', COUNT(*) FROM products UNION ALL SELECT 'offers', COUNT(*) FROM offers UNION ALL SELECT 'sales', COUNT(*) FROM sales UNION ALL SELECT 'users', COUNT(*) FROM users UNION ALL SELECT 'markers', COUNT(*) FROM migration_state WHERE key = 'demo_seed_v2'";
  const [first, ver] = await query([countSql, 'PRAGMA user_version']);
  const c1 = counts(first);
  console.log('after first load:', JSON.stringify(c1), 'user_version', ver[0].user_version);
  check('seed ran once', c1.stores === 2 && c1.products === 60 && c1.offers === 13 && c1.sales === 30 && c1.users === 4 && c1.markers === 1 && ver[0].user_version === 10);
  await load(); // reload: the data persists and nothing is seeded again
  const [second] = await query([countSql]);
  const c2 = counts(second);
  check('reload keeps the data, no second seed', JSON.stringify(c1) === JSON.stringify(c2), JSON.stringify(c2));
  await shot('ozone_02_tiles_after_reload');

  // Checkout: two Oreo (Buy 1 Get 1), Maggi (Buy 1 Get 1), Cola (20 % off) and three Tata Tea (450.00) reach 500.00: Dairy Milk unlocks.
  await click(width / 2, 28);
  for (const code of ['8901234560015', '8901234560015', '8901234560020', '8901234560000', '8901234560011', '8901234560011', '8901234560011']) { await insert(code); await key('Enter', 13); await sleep(900); }
  await shot('ozone_03_cart_with_offers_and_unlocked_gift');
  await enableSemantics();
  const sumHtml = await ev('document.body.innerHTML');
  check('India summary: GST Amount with CGST and SGST rows', sumHtml.includes('GST Amount') && sumHtml.includes('CGST') && sumHtml.includes('SGST'));
  check('India forex: USD selected, rate 83.2', sumHtml.includes('USD') && sumHtml.includes('83.2') && !sumHtml.includes('8.561'));
  const open = await openForex();
  await shot('ozone_03b_forex_open');
  check('India forex list: USD, EUR, AED only', open.includes('EUR') && open.includes('AED') && !open.includes('KES'));
  await key('Escape', 27); await sleep(500);
  await click(width / 2, 28);
  await key('F2', 113); await sleep(700);
  await key('Enter', 13); await sleep(2500);
  await shot('ozone_04_receipt');
  await enableSemantics();
  const html = await ev('document.body.innerHTML');
  check('India receipt shows GST, CGST and SGST', html.includes('CGST') && html.includes('SGST') && html.includes('GST'));
  check('receipt opens and shows the offer, the free item and the cashier', html.includes('Retail tax invoice') && html.includes('Buy 1 Get 1') && html.includes('Free gift') && html.includes('Cashier: Chitra Cashier'));
  await sleep(2500);
  const [sale, lines] = await query([
    "SELECT number, store_id, counter_id, user_id, user_name, currency_code, total_minor FROM sales WHERE number = 'AX000019' AND store_id = 'demo-store-ozone'",
    "SELECT product_name, price_minor, qty_milli, discount_bp, offer_kind, offer_saving_minor, is_gift FROM sale_lines WHERE sale_id IN (SELECT id FROM sales WHERE number = 'AX000019' AND store_id = 'demo-store-ozone') ORDER BY line_no",
  ]);
  console.log('new sale:', JSON.stringify(sale), '\nlines:', JSON.stringify(lines));
  check('the sale is stamped with store, counter, cashier and currency', sale.length === 1 && sale[0].counter_id && sale[0].user_id === 'demo-user-cashier1' && sale[0].user_name === 'Chitra Cashier' && sale[0].currency_code === 'INR');
  check('the promotion line is half price (discount 5000 bp) with its saving', lines.some((l) => l.offer_kind === 'promotion' && l.discount_bp === 5000 && l.offer_saving_minor > 0));
  check('the discount line carries its offer', lines.some((l) => l.offer_kind === 'discount' && l.discount_bp === 2000));
  check('the free item is sold at 0', lines.some((l) => l.is_gift === 1 && l.price_minor === 0));
} else {
  await click(width / 2, 28);
  for (const code of ['6001234560000', '6001234560002', '6001234560003']) { await insert(code); await key('Enter', 13); await sleep(900); }
  await enableSemantics();
  const html = await ev('document.body.innerHTML');
  await shot('kampala_02_semantics_on');
  check('Kampala shows its own store name and currency (USh), 0 decimals', html.includes('Axpert Mart - Kampala') && html.includes('USh 1,800'));
  check('no rupee sign in the second store', !html.includes('₹'));
  check('Kampala summary: VAT Amount, no GST/CGST/SGST anywhere', html.includes('VAT Amount') && !html.includes('GST'));
  check('Kampala forex: USD selected, rate 3700', html.includes('USD') && html.includes('3700') && !html.includes('83.2'));
  const open = await openForex();
  await shot('kampala_03_forex_open');
  check('Kampala forex list: USD, EUR, KES (no AED)', open.includes('EUR') && open.includes('KES') && !open.includes('AED'));
  await key('Escape', 27); await sleep(500);
  await click(width / 2, 28);
  await key('F2', 113); await sleep(700);
  await key('Enter', 13); await sleep(2500);
  await shot('kampala_04_receipt');
  const receipt = await ev('document.body.innerHTML');
  check('Kampala receipt shows VAT and no GST/CGST/SGST', receipt.includes('VAT') && !receipt.includes('GST') && receipt.includes('Retail tax invoice'));
  const [a] = await query(["SELECT COUNT(*) n FROM sales WHERE store_id = 'demo-store-kampala'"]);
  check('Kampala has its own 12 sales (plus this one)', a[0].n === 13);
}
check('no console errors', logs.length === 0, logs.slice(0, 2).join(' | ').slice(0, 200));
const failed = checks.filter((c) => !c.ok);
console.log(`\n${checks.length} checks, ${failed.length} failed. Screenshots in ${outDir}`);
ws.close(); proc.kill();
process.exit(failed.length ? 1 : 0);
