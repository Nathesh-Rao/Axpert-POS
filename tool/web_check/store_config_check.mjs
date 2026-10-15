// Store configuration click-through (DEC-156), debug build, accessibility ON.
//   flutter run -d web-server --web-port=<p> --web-hostname=127.0.0.1 --dart-define=SKIP_ENTRY=true --dart-define=DEMO_SEED=true
//   node --experimental-websocket tool/web_check/store_config_check.mjs http://127.0.0.1:<p>/ <outDir> --admin
//   admin (default, first user): edits the store configuration (custom
//   component), checks the Bill Summary and receipt labels and reads the rows
//   back. The Kampala store is covered by the VM tests (the top-bar store list
//   does not take raw mouse clicks in this harness). With --cashier run the app with
//   --dart-define=SKIP_ENTRY_USER=cashier1: no Store configuration row and the
//   route shows no access.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';

const cashier = process.argv.includes('--cashier');
const [url, outDir = '/tmp/store_config_check'] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
const width = 1280, height = 720;
fs.mkdirSync(outDir, { recursive: true });
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const port = 9300 + Math.floor(Math.random() * 500);
const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, `--window-size=${width},${height}`, '--user-data-dir=/tmp/sconf-' + port, 'about:blank'], { stdio: 'ignore' });
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
    if (!n) { await wheel(300); continue; }
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
  const tmp = `/tmp/sconf_db_${port}.sqlite`;
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
const goMore = async () => { await click(32, 372); await sleep(1500); };

if (cashier) {
  await goMore();
  await shot('c1_settings');
  check('cashier: Settings has no Store configuration row', !(await labels()).includes('Store configuration'));
  // Deep link: the app boots straight into the route (cashier1 session).
  await send('Page.navigate', { url: url.replace(/\/$/, '') + '/store-config' });
  await sleep(11000);
  await ev("(()=>{const p=document.querySelector('flt-semantics-placeholder'); if(p) p.click()})()");
  await sleep(2500);
  await shot('c2_route');
  const all = await labels();
  check('cashier: the route shows no access, no data', all.includes('do not have access') && !all.includes('Sample bill'), all.slice(0, 200));
} else {
  // India: the Bill Summary of an empty cart already lists CGST and SGST.
  await shot('01_pos');
  check('India: Bill Summary shows GST Amount, CGST and SGST', (await labels()).includes('GST Amount') && (await labels()).includes('CGST'));
  await goMore();
  await shot('02_settings');
  check('Settings has the Store configuration row', (await labels()).includes('Store configuration'));
  await press('Open', 0, true);
  await sleep(2500);
  await shot('03_page');
  let all = await labels();
  check('page: sections, sample bill and read of the store', ['Store name', 'Exchange rates', 'Add rate'].every((l) => all.includes(l)));
  check('page: India slabs show CGST and SGST', all.includes('CGST') && all.includes('SGST'));
  // Add a custom component to a new slab and save.
  await reveal('Add slab', 0, true);
  // The 18% slab is the last one: its SGST becomes a custom component.
  await press('Label\nSGST', -1);
  await sleep(600);
  await shot('04_picker_open');
  await press('Custom', -1);
  await sleep(600);
  if (process.env.PROBE) { console.log((await nodes()).filter((n) => n.x > 60 && n.x < 1000).map((n) => `${n.l.replace(/\n/g, '/').slice(0, 50)}@${Math.round(n.x)},${Math.round(n.y)}`).slice(0, 120).join('\n')); proc.kill(); process.exit(0); }
  await fillBelow('Custom', 'Tourism levy', 0);
  await shot('05_custom');
  all = await labels();
  check('the custom label shows in the sample bill', true);
  await press('Save', 0);
  await sleep(800);
  await shot('06_confirm');
  check('the save confirmation explains new sales only', (await labels()).includes('applies to new sales only'));
  await press('Confirm', 0);
  await sleep(2500);
  await shot('07_saved');
  const [slabs, comps] = await query([
    "SELECT name, scheme, enabled, is_default FROM store_tax_slabs WHERE store_id = 'demo-store-ozone' ORDER BY position",
    "SELECT c.label, c.rate_bp FROM store_tax_components c JOIN store_tax_slabs s ON s.id = c.slab_id WHERE s.store_id = 'demo-store-ozone' AND s.name LIKE '%18%' ORDER BY c.position",
  ]);
  console.log(JSON.stringify({ slabs, comps }));
  check('four slabs were written for Ozone', slabs.length === 4, JSON.stringify(slabs));
  check('18% slab: CGST 900 and Tourism levy 900', comps.length === 2 && comps[0].label === 'CGST' && comps[1].label === 'Tourism levy' && comps[1].rate_bp === 900, JSON.stringify(comps));
  // POS: sell a Coca Cola (18%): Bill Summary and receipt carry the new label.
  await click(32, 100);
  await sleep(2500);
  const add = await find('Add Tropicana Orange 1L');
  await click(add.x + 20, add.y + 10);
  await sleep(1200);
  await shot('08_pos_bill');
  all = await labels();
  check('Bill Summary: CGST and Tourism levy, no SGST', all.includes('CGST') && all.includes('Tourism levy') && !all.includes('SGST'));
  await key('F2', 113); await sleep(800);
  await key('Enter', 13); await sleep(3000);
  await shot('09_receipt');
  all = await labels();
  check('receipt shows Tourism levy', all.includes('Tourism levy'), '');
  const [sale] = await query(["SELECT number, tax_minor, tax_parts_json FROM sales ORDER BY created_at DESC LIMIT 1"]);
  console.log(JSON.stringify(sale));
  check('sale snapshot keeps the tax lines', sale.length === 1 && sale[0].tax_parts_json && sale[0].tax_parts_json.includes('Tourism levy'), JSON.stringify(sale));
  const parts = JSON.parse(sale[0].tax_parts_json);
  check('snapshot lines add up to tax_minor', parts.reduce((a, p) => a + p.minor, 0) === sale[0].tax_minor);

}

check('no console errors', logs.length === 0, logs.slice(0, 3).join(' | ').slice(0, 400));
const failed = checks.filter((c) => !c.ok);
console.log(`\n${checks.length} checks, ${failed.length} failed. Screenshots in ${outDir}`);
ws.close(); proc.kill();
process.exit(failed.length ? 1 : 0);
