// Debug-build click-through (standing check, S7+): drives a `flutter run -d
// web-server` DEBUG session in headless Chrome through every route and every
// dialog with seeded data and FAILS on any console error, any
// "setState() or markNeedsBuild()" text, any "EXCEPTION CAUGHT", any
// "Another exception was thrown" or any Flutter error widget (red screen).
// Release builds cannot show these (they are debug-only asserts).
//
// usage:
//   flutter run -d web-server --web-port=8170 --web-hostname=127.0.0.1   (wait: "is being served")
//   node --experimental-websocket tool/web_check/debug_check.mjs http://127.0.0.1:8170/ [outDir] [width height] [--semantics]
// --semantics turns web accessibility ON right after load (what pressing Tab
// at load does: it activates the `flt-semantics-placeholder` element), then
// runs the same click-through. Run BOTH modes when the widget structure
// changes: the semantics engine has its own asserts ("Child #N is missing in
// the tree", "Unexpected null value", semantics.dart) that only show then.
// The debug dev server accepts ONE page load per `flutter run`: run this once
// per session and stop `flutter run` afterwards. localStorage is seeded
// BEFORE the app starts (a reload would not work), then the script adds 3
// items, selects member MG1003 (Priya Nair, 400 points) and clicks through.
// Coordinates are for the default 1280 x 720 window.
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import zlib from 'node:zlib';

const semanticsOn = process.argv.includes('--semantics');
const [url, outDir = '/tmp/debug_check', widthArg = '1280', heightArg = '720'] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
const width = Number(widthArg), height = Number(heightArg);
fs.mkdirSync(outDir, { recursive: true });
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ---- seeded localStorage: three stored sales with lines (today) ----
const product = (id, name, code, price, gst) => ({ id, name, code, barcode: String(8901234567890 + id), priceMinor: price, category: 'Beverages', sub: 'Soft Drinks', stock: 40, gst, image: id, favourite: false });
const line = (p, qtyMilli, priceMinor) => ({ product: p, qtyMilli, priceMinor, discountBp: 0 });
const cart = (lines) => ({ lines, customer: 'walk', saleType: 'Cash', discountType: 'percent', billDiscountBp: 0, billDiscountMinor: 0, reason: '', points: 0, note: '' });
const sale = (n, minutesAgo, customer, mode, lines, total) => ({
  number: 'AX' + String(n).padStart(6, '0'), date: new Date(Date.now() - minutesAgo * 60000).toISOString(), store: 'Maison Galaxy', customer,
  cart: cart(lines), totals: { items: lines.length, qtyMilli: 2000, valueMinor: total, subtotalMinor: total, discountMinor: 0, taxMinor: 0, pointsMinor: 0, totalMinor: total },
  mode, tenderedMinor: total, changeMinor: 0, returned: {},
});
const cola = product(0, 'Coca Cola 500ml', 'BDV001', 4000, 18), pepsi = product(1, 'Pepsi 500ml', 'BDV002', 4000, 12);
const sales = [
  sale(1, 180, 'Ananya Sharma', 'Cash', [line(cola, 2000, 4000)], 8000),
  sale(2, 120, 'Walk-in Customer', 'Card', [line(pepsi, 1500, 4000)], 6000),
  sale(3, 60, 'Rahul Mehta', 'Credit', [line(cola, 1000, 4000), line(pepsi, 1000, 4000)], 8000),
];
const seed = { 'flutter.axpert-sales': JSON.stringify(JSON.stringify(sales)) };

// ---- CDP plumbing ----
const port = 9300 + Math.floor(Math.random() * 500);
const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, `--window-size=${width},${height}`, '--user-data-dir=/tmp/dbgchk-' + port, 'about:blank'], { stdio: 'ignore' });
let targets;
for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {} await sleep(200); }
const ws = new WebSocket(targets.find((t) => t.type === 'page').webSocketDebuggerUrl);
await new Promise((r) => (ws.onopen = r));
let id = 0; const pending = new Map(); let logs = [];
ws.onmessage = (m) => {
  const d = JSON.parse(m.data);
  if (d.id && pending.has(d.id)) { pending.get(d.id)(d.result); pending.delete(d.id); }
  else if (d.method === 'Runtime.consoleAPICalled') logs.push({ type: d.params.type, text: d.params.args.map((a) => a.value ?? a.description).join(' ') });
  else if (d.method === 'Runtime.exceptionThrown') logs.push({ type: 'exception', text: d.params.exceptionDetails.exception?.description ?? d.params.exceptionDetails.text });
  else if (d.method === 'Log.entryAdded') logs.push({ type: 'log.' + d.params.entry.level, text: d.params.entry.text + ' ' + (d.params.entry.url ?? '') });
};
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
await send('Runtime.enable'); await send('Log.enable'); await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
await send('Page.addScriptToEvaluateOnNewDocument', { source: `try{const d=${JSON.stringify(seed)};for(const k in d)localStorage.setItem(k,d[k])}catch(e){}` });
const click = async (x, y) => { await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y }); await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 }); await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 }); };
const insert = (text) => send('Input.insertText', { text });
const key = async (k, vk) => { await send('Input.dispatchKeyEvent', { type: 'keyDown', key: k, code: k, windowsVirtualKeyCode: vk }); await send('Input.dispatchKeyEvent', { type: 'keyUp', key: k, code: k, windowsVirtualKeyCode: vk }); };
const shot = async (name) => { const r = await send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync(`${outDir}/${name}.png`, Buffer.from(r.data, 'base64')); return Buffer.from(r.data, 'base64'); };

// ---- red error-widget detection from the screenshot pixels ----
function redFraction(png) {
  let pos = 8, w = 0, h = 0, ctype = 0; const idat = [];
  while (pos < png.length) { const n = png.readUInt32BE(pos), t = png.toString('ascii', pos + 4, pos + 8); const b = png.subarray(pos + 8, pos + 8 + n); if (t === 'IHDR') { w = b.readUInt32BE(0); h = b.readUInt32BE(4); ctype = b[9]; } else if (t === 'IDAT') idat.push(b); pos += 12 + n; }
  const ch = ctype === 6 ? 4 : 3, raw = zlib.inflateSync(Buffer.concat(idat)), stride = w * ch;
  let prev = Buffer.alloc(stride), red = 0, total = 0;
  for (let y = 0; y < h; y++) {
    const f = raw[y * (stride + 1)], line = Buffer.from(raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1)));
    for (let i = 0; i < stride; i++) {
      const a = i >= ch ? line[i - ch] : 0, b = prev[i], c = i >= ch ? prev[i - ch] : 0;
      if (f === 1) line[i] = (line[i] + a) & 255; else if (f === 2) line[i] = (line[i] + b) & 255; else if (f === 3) line[i] = (line[i] + ((a + b) >> 1)) & 255;
      else if (f === 4) { const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c); line[i] = (line[i] + (pa <= pb && pa <= pc ? a : pb <= pc ? b : c)) & 255; }
    }
    if (y % 6 === 0) for (let x = 0; x < w; x += 6) { const r = line[x * ch], g = line[x * ch + 1], bl = line[x * ch + 2]; total++; if (r > 100 && r < 190 && g < 70 && bl < 70) red++; }
    prev = line;
  }
  return red / total;
}

// ---- wait for the debug app (DDC compile + load can take a minute or more) ----
await send('Page.navigate', { url });
const t0 = Date.now();
while (Date.now() - t0 < 240000) { if (await (async () => (await send('Runtime.evaluate', { expression: "!!document.querySelector('flt-glass-pane, flutter-view')", returnByValue: true })).result?.value)()) break; await sleep(500); }
await sleep(6000);
if (semanticsOn) {
  const r = await send('Runtime.evaluate', { expression: "(()=>{const p=document.querySelector('flt-semantics-placeholder'); if(!p) return 'no placeholder'; p.click(); return 'enabled'})()", returnByValue: true });
  console.log('web accessibility:', r.result?.value);
  await sleep(3000);
}

const BAD = [/Assertion failed/, /Unexpected null value/, /is missing in the tree/, /semantics\.dart/, /EXCEPTION CAUGHT/, /Another exception was thrown/, /setState\(\) or markNeedsBuild\(\)/, /RenderFlex overflowed/, /Unhandled/i];
const results = [];
async function step(name, fn) {
  logs = [];
  let error = null;
  try { await fn(); } catch (e) { error = String(e); }
  await sleep(1300);
  const png = await shot(name.replace(/[^a-z0-9]+/gi, '_'));
  const red = redFraction(png);
  const bad = logs.filter((l) => l.type === 'error' || l.type === 'exception' || l.type === 'log.error' || BAD.some((re) => re.test(l.text)));
  const ok = !error && !bad.length && red < 0.08;
  results.push({ name, ok, red: +red.toFixed(3), errors: bad.length, first: bad[0]?.text.split('\n')[0]?.slice(0, 110) ?? error ?? '' });
  if (!ok) fs.writeFileSync(`${outDir}/FAIL_${name.replace(/[^a-z0-9]+/gi, '_')}.log`, bad.map((l) => `[${l.type}] ${l.text}`).join('\n'));
}
const NAV = { POS: [32, 95], Products: [32, 170], Customers: [32, 245], Sales: [32, 320], Returns: [32, 395], Reports: [32, 470], More: [32, 660] };
const page = (n) => step(`page ${n}`, () => click(...NAV[n]));
const esc = async () => { await key('Escape', 27); await sleep(500); };

await step(semanticsOn ? 'start on POS (semantics on)' : 'start on POS', async () => {});
await step('add 3 items', async () => { await click(width / 2, 28); for (const code of ['8901234567895', '8901234567896', '8901234567897']) { await insert(code); await key('Enter', 13); await sleep(900); } });
await step('select member MG1003', async () => { await click(1020, 375); await insert('MG1003'); await sleep(800); });

// every page from POS and back, then the order that showed the red screen
for (const n of ['Products', 'Customers', 'Sales', 'Returns', 'Reports', 'More']) { await page(n); await page('POS'); }
for (const n of ['Reports', 'Customers', 'Reports', 'Products', 'Reports', 'Sales', 'Returns', 'More', 'Reports', 'POS']) await page(n);
for (const n of ['More', 'Returns', 'Sales', 'Reports', 'Customers', 'Products', 'POS']) await page(n);

// dialogs over POS (cart, member) and over Reports
const MENU = [1248, 27];
const dialogs = [
  ['profile', async () => { await click(...MENU); await sleep(500); await click(1160, 86); }],
  ['settings', async () => { await click(...MENU); await sleep(500); await click(1164, 128); }],
  ['shortcuts', async () => { await click(...MENU); await sleep(500); await click(1164, 170); }],
  ['close counter', async () => { await click(...MENU); await sleep(500); await click(1160, 212); }],
  ['cash F2', async () => { await key('F2', 113); }],
  ['recall F5', async () => { await key('F5', 116); }],
  ['discount F6', async () => { await key('F6', 117); }],
  ['scan', async () => { await click(1053, 28); }],
  ['price check', async () => { await click(1074, 653); }],
  ['discount quick action', async () => { await click(1004, 653); }],
  ['quick action row 2 left', async () => { await click(1004, 688); }],
  ['quick action row 2 right', async () => { await click(1215, 688); }],
  ['customer picker', async () => { await click(782, 194); }],
  ['add customer', async () => { await click(866, 194); }],
  ['order menu', async () => { await click(908, 104); }],
  ['rename counter', async () => { await click(908, 104); await sleep(500); await click(820, 160); }],
  ['add note', async () => { await click(908, 104); await sleep(500); await click(800, 202); }],
  ['print draft (receipt)', async () => { await click(908, 104); await sleep(500); await click(803, 244); }],
  ['reprint', async () => { await click(1074, 688); }],
  ['clear cart (confirm)', async () => { await click(1144, 688); }],
];
const POS_ONLY = new Set(['price check', 'discount quick action', 'quick action row 2 left', 'quick action row 2 right', 'customer picker', 'add customer', 'order menu', 'rename counter', 'add note', 'print draft (receipt)', 'reprint', 'clear cart (confirm)']);
for (const home of ['POS', 'Reports']) {
  if (home !== 'POS') await page(home);
  for (const [name, fn] of dialogs) {
    if (home === 'Reports' && POS_ONLY.has(name)) continue; // controls that exist only on the POS page
    await step(`dialog ${name} on ${home}`, fn);
    await esc();
  }
}
await page('Sales');
await step('receipt via View receipt', () => click(864, 323));
await esc();
await page('POS');

console.log('\nstep | ok | red screen share | console errors | first error');
for (const r of results) console.log(`${r.ok ? 'ok  ' : 'FAIL'} | ${r.name} | ${r.red} | ${r.errors} | ${r.first}`);
const failed = results.filter((r) => !r.ok);
console.log(`\n${results.length} steps, ${failed.length} failed. Screenshots and FAIL_*.log in ${outDir}`);
ws.close(); proc.kill();
process.exit(failed.length ? 1 : 0);
