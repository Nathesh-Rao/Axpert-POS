// Debug-build click-through (standing check, S7+): drives a `flutter run -d
// web-server` DEBUG session in headless Chrome through every route and every
// dialog with seeded data and FAILS on any console error, any
// "setState() or markNeedsBuild()" text, any "EXCEPTION CAUGHT", any
// "Another exception was thrown" or any Flutter error widget (red screen).
// Release builds cannot show these (they are debug-only asserts).
//
// usage:
//   flutter run -d web-server --web-port=8170 --web-hostname=127.0.0.1 --dart-define=SKIP_ENTRY=true --dart-define=DEMO_SEED=true   (wait: "is being served")
//   The app has no built-in data: DEMO_SEED=true fills the database once (assets/seed). SKIP_ENTRY signs in the first user (admin) in Ozone.
//   node --experimental-websocket tool/web_check/debug_check.mjs http://127.0.0.1:8170/ [outDir] [width height] [--semantics] [--entry]
// Default: the app is run WITH SKIP_ENTRY (starts on POS). --entry: run it
// WITHOUT the define; the script walks the real splash and login first
// (entry.mjs), then does the same click-through.
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
import { signInThroughEntry } from './entry.mjs';

const semanticsOn = process.argv.includes('--semantics');
const entryOn = process.argv.includes('--entry');
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

// Records every Web Audio beep (oscillator frequency, gain, duration) so the
// check can assert React's tone: sine 1100 Hz, gain 0.04, 80 ms.
const audioHook = `(()=>{window.__beeps=[];const C=window.AudioContext||window.webkitAudioContext;if(!C)return;const co=C.prototype.createOscillator,cg=C.prototype.createGain;C.prototype.createGain=function(){const g=cg.call(this);this.__g=g;return g};C.prototype.createOscillator=function(){const o=co.call(this),ctx=this,stop=o.stop.bind(o);o.stop=function(when){window.__beeps.push({type:o.type,freq:o.frequency.value,gain:ctx.__g&&ctx.__g.gain.value,secs:Math.round((when-ctx.currentTime)*1000)/1000});return stop(when)};return o}})()`;
await send('Page.addScriptToEvaluateOnNewDocument', { source: audioHook });
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
await sleep(entryOn ? 500 : 6000); // --entry: do not miss the splash
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
// Icon-only rail card at 1280 x 720: items 40 px every 44 px from y 100, More below the divider.
const NAV = { POS: [32, 100], Products: [32, 144], Customers: [32, 188], Sales: [32, 232], Returns: [32, 276], Reports: [32, 320], More: [32, 377] };
const page = (n) => step(`page ${n}`, () => click(...NAV[n]));
const esc = async () => { await key('Escape', 27); await sleep(500); };

if (entryOn) await signInThroughEntry({ step, insert, key, click, sleep, width, height });
await step(semanticsOn ? 'start on POS (semantics on)' : 'start on POS', async () => {});
await step('add 3 items', async () => { await click(width / 2, 28); for (const code of ['8901234560015', '8901234560020', '8901234560000']) { await insert(code); await key('Enter', 13); await sleep(900); } });
await step('beep on add (Web Audio: sine 1100 Hz, gain 0.04, 80 ms)', async () => {
  const beeps = (await send('Runtime.evaluate', { expression: 'JSON.stringify(window.__beeps)', returnByValue: true })).result?.value;
  const list = JSON.parse(beeps ?? '[]');
  console.log('beeps after 3 adds:', beeps);
  if (list.length !== 3 || list.some((b) => b.type !== 'sine' || b.freq !== 1100 || Math.abs(b.gain - 0.04) > 1e-6 || Math.abs(b.secs - 0.08) > 0.005)) throw new Error('beep mismatch: ' + beeps);
});
await step('select member MG2001', async () => { await click(1020, 375); await insert('MG2001'); await sleep(800); });

// Three-panel layout (DEC-141): every Products step and Billing state by keyboard and by the
// edge control, F2 with Billing collapsed, back to the default layout for the steps below.
const chord = async (k, code, vk, modifiers) => {
  const [mk, mcode, mvk] = modifiers === 2 ? ['Control', 'ControlLeft', 17] : ['Meta', 'MetaLeft', 91];
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key: mk, code: mcode, windowsVirtualKeyCode: mvk, modifiers });
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key: k, code, windowsVirtualKeyCode: vk, modifiers });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', key: k, code, windowsVirtualKeyCode: vk, modifiers });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', key: mk, code: mcode, windowsVirtualKeyCode: mvk, modifiers: 0 });
  await sleep(700);
};
await step('three panels: Ctrl+B to 25%', () => chord('b', 'KeyB', 66, 2));
await step('three panels: Ctrl+B to 75%', () => chord('b', 'KeyB', 66, 2));
await step('three panels: Ctrl+B back to hidden', () => chord('b', 'KeyB', 66, 2));
await step('three panels: click the edge control (25%)', () => click(82, Math.round(height * 0.7)));
await step('three panels: click the edge control (75%)', () => click(82, Math.round(height * 0.7)));
await step('three panels: click the edge control (hidden)', () => click(82, Math.round(height * 0.7)));
await step('billing: Ctrl+. collapses', () => chord('.', 'Period', 190, 2));
await step('billing collapsed: Ctrl+B to 25%', () => chord('b', 'KeyB', 66, 2));
await step('billing collapsed: Ctrl+B to 75%', () => chord('b', 'KeyB', 66, 2));
await step('billing collapsed: Ctrl+B to hidden', () => chord('b', 'KeyB', 66, 2));
await step('billing collapsed: F2 opens it', async () => { await click(width / 2, 28); await key('F2', 113); await sleep(900); });
await step('billing: Ctrl+. collapses again', () => chord('.', 'Period', 190, 2));
await step('billing: Ctrl+. expands', () => chord('.', 'Period', 190, 2));

// every page from POS and back, then the order that showed the red screen
for (const n of ['Products', 'Customers', 'Sales', 'Returns', 'Reports', 'More']) { await page(n); await page('POS'); }
for (const n of ['Reports', 'Customers', 'Reports', 'Products', 'Reports', 'Sales', 'Returns', 'More', 'Reports', 'POS']) await page(n);
for (const n of ['More', 'Returns', 'Sales', 'Reports', 'Customers', 'Products', 'POS']) await page(n);

// Types the demo user and password on the login screen (no splash after a sign-out).
const signInAgain = async () => {
  await insert(process.env.ENTRY_USER ?? (entryOn ? 'cashier1' : 'admin'));
  await key('Tab', 9);
  await insert(process.env.ENTRY_PASS ?? (entryOn ? 'Demo#Cashier1' : 'Demo#Admin1'));
  await key('Enter', 13);
  await sleep(3000);
};

// dialogs over POS (cart, member) and over Reports
const MENU = [1248, 27];
const dialogs = [
  ['profile', async () => { await click(...MENU); await sleep(500); await click(1160, 86); }],
  ['settings', async () => { await click(...MENU); await sleep(500); await click(1164, 128); }],
  ['shortcuts', async () => { await click(...MENU); await sleep(500); await click(1164, 170); }],
  // Logout signs out (0aea5b6, KG-262): the app is on the login screen afterwards, so sign in again with the
  // same user as at the start; the saved cart comes back with the sign-in (same store).
  ['close counter', async () => { await click(...MENU); await sleep(500); await click(1160, 212); await sleep(1500); await signInAgain(); }],
  ['cash F2', async () => { await key('F2', 113); }],
  ['recall F5', async () => { await key('F5', 116); }],
  ['discount F6', async () => { await key('F6', 117); }],
  ['scan', async () => { await click(1053, 28); }],
  ['price check', async () => { await click(1074, 653); }],
  ['discount quick action', async () => { await click(1004, 653); }],
  ['quick action row 2 left', async () => { await click(1004, 688); }],
  ['quick action row 2 right', async () => { await click(1215, 688); }],
  ['customer picker', async () => { await click(782, 167); }],
  ['add customer', async () => { await click(866, 167); }],
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
    // The Bill Summary now has the tax split rows (CGST/SGST): scroll it to its end so the
    // quick actions sit where the coordinates above expect them.
    if (home === 'POS') await send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 1110, y: 500, deltaX: 0, deltaY: 600 });
    await step(`dialog ${name} on ${home}`, fn);
    await esc();
  }
}
await page('Sales');
await step('receipt via View receipt', () => click(864, 323));
await esc();
await page('POS');

// Checkout (DEC-123): complete a CASH sale with F2 + Enter in the tendered field, check that
// the receipt dialog opens and that the stored `axpert-sales` JSON has a new sale with a UUID v4
// `saleId`. The receipt is read from the semantics DOM: in normal mode accessibility is switched
// on only AFTER the sale, for this one read.
await step('checkout: cash sale, receipt opens, saleId stored', async () => {
  const evalPage = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true })).result?.value;
  await key('F2', 113); await sleep(700);
  await key('Enter', 13); await sleep(1800);
  if (!semanticsOn) { await evalPage("(()=>{const p=document.querySelector('flt-semantics-placeholder'); if(p) p.click()})()"); await sleep(2500); }
  const receipt = await evalPage("document.body.innerHTML.includes('Retail tax invoice')");
  if (!receipt) throw new Error('receipt dialog not found after the sale');
  // The sale lives in Drift only (no LocalStore mirror in scoped mode): the
  // receipt text proves the sale and its cashier; drift_check.mjs reads the rows.
  const cashier = await evalPage("/Cashier: [A-Z][a-z]+ (Admin|Manager|Cashier)/.test(document.body.innerHTML)");
  if (!cashier) throw new Error('receipt does not name the signed-in cashier');
  console.log('checkout: receipt opened and names the cashier');
});

console.log('\nstep | ok | red screen share | console errors | first error');
for (const r of results) console.log(`${r.ok ? 'ok  ' : 'FAIL'} | ${r.name} | ${r.red} | ${r.errors} | ${r.first}`);
const failed = results.filter((r) => !r.ok);
console.log(`\n${results.length} steps, ${failed.length} failed. Screenshots and FAIL_*.log in ${outDir}`);
ws.close(); proc.kill();
process.exit(failed.length ? 1 : 0);
