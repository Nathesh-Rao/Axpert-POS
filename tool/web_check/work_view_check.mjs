// Release-build check of the catalog / cart work-area views (DEC-139, DEC-140).
//   flutter build web --release --dart-define=SKIP_ENTRY=true --dart-define=DEMO_SEED=true --dart-define=SKIP_ENTRY_USER=cashier1
//   python3 tool/web_check/serve.py build/web 8330 &
//   node --experimental-websocket tool/web_check/work_view_check.mjs http://127.0.0.1:8330/ <outDir> <width> <height>
// Empty cart = full catalog; the first tile click shows the cart, later ones keep the catalog and count in the tab;
// the tab, Ctrl+B and Cmd+B switch; a search add switches to the cart; Escape
// goes back to the cart; hold returns to the catalog, recall to the cart.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';

const [url, outDir = '/tmp/work_view', widthArg = '1280', heightArg = '720'] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
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



const checks = [];
const check = (name, ok, detail = '') => { checks.push({ name, ok }); console.log(`${ok ? 'ok  ' : 'FAIL'} | ${name} ${detail}`); };
const html = () => ev('document.body.innerHTML');
const CTRL = 2, META = 4;
const mod = async (k, code, vk, modifiers) => {
  // The framework tracks the pressed keys itself, so the modifier key goes down first.
  const [mk, mcode, mvk] = modifiers === 2 ? ['Control', 'ControlLeft', 17] : ['Meta', 'MetaLeft', 91];
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key: mk, code: mcode, windowsVirtualKeyCode: mvk, modifiers });
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key: k, code, windowsVirtualKeyCode: vk, modifiers });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', key: k, code, windowsVirtualKeyCode: vk, modifiers });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', key: mk, code: mcode, windowsVirtualKeyCode: mvk, modifiers: 0 });
  await sleep(1600);
};


await load();
await enableSemantics();
const catalogUp = (h) => h.includes('Soft Drinks') && h.includes('Favourites');
const cartUp = (h) => h.includes('Disc %') && h.includes('Qty');
let h = await html();
await shot('01_catalog_empty');
check('an empty cart shows the full catalog and a disabled Cart (0) tab', catalogUp(h) && h.includes('Cart (0)'));
// The first tile click on an empty cart shows the cart (DEC-140).
await click(Math.round(width * 0.27), Math.round(height * 0.43)); await sleep(1500);
h = await html();
await shot('02_cart_after_first_tile_click');
check('the first tile click on an empty cart switches to the cart', cartUp(h) && !catalogUp(h));
// Back to the products; more tile clicks keep the catalog (the empty-cart header is gone).
await click(97, Math.round(height / 2)); await sleep(1500);
await shot('02b_catalog_with_item');
await click(Math.round(width * 0.27), Math.round(height * 0.67)); await sleep(1200);
await click(Math.round(width * 0.57), Math.round(height * 0.67)); await sleep(1500);
await shot('02c_catalog_after_tile_clicks');
h = await html();
check('later tile clicks keep the catalog and the tab counts the lines', catalogUp(h) && h.includes('Cart (3)'), (h.match(/Cart \(\d+\)/) ?? [''])[0]);
await click(Math.round(width * 0.27), Math.round(height * 0.67)); await sleep(900);
h = await html();
check('picking an item again still stays in the catalog', catalogUp(h) && h.includes('Cart (3)'));
// Tab -> cart.
await click(97, Math.round(height / 2)); await sleep(1500);
await shot('03_cart_view');
h = await html();
check('the tab shows the dense cart (tab now reads Products)', cartUp(h) && !h.includes('Soft Drinks'));
// Ctrl+B -> catalog, Cmd+B -> cart.
await mod('b', 'KeyB', 66, CTRL);
h = await html();
check('Ctrl+B goes back to the catalog', catalogUp(h));
await mod('b', 'KeyB', 66, META);
h = await html();
check('Cmd+B shows the cart', cartUp(h));
// Search add from the catalog switches to the cart.
await mod('b', 'KeyB', 66, CTRL);
await click(width / 2, 28);
await insert('8901234560015'); await key('Enter', 13); await sleep(1500);
h = await html();
check('an add through the search box switches to the cart', cartUp(h) && h.includes('Oreo Biscuit 120g'));
await shot('04_cart_after_search_add');
// Escape from the catalog returns to the cart.
await mod('b', 'KeyB', 66, CTRL);
await key('Escape', 27); await sleep(1200);
h = await html();
check('Escape in the catalog returns to the cart', cartUp(h));
// Hold the bill: the cart is empty, the catalog is back; recall shows the cart.
await key('F4', 115); await sleep(1500);
h = await html();
check('holding the last bill returns to the catalog', catalogUp(h) && h.includes('Cart (0)'));
await shot('05_catalog_after_hold');
await key('F5', 116); await sleep(1200);
await click(width / 2, height / 2 + 44); await sleep(1500);
h = await html();
check('recalling the held bill shows the cart', cartUp(h) && h.includes('Oreo Biscuit 120g'));
// Clear cart (footer button, then confirm with Enter).
const clearX = Math.round(width * 0.46), clearY = height - 52;
await click(clearX, clearY); await sleep(900);
await shot('06_confirm_clear');
await click(width / 2 + 104, height / 2 + 40); await sleep(1800);
h = await html();
check('clearing the cart returns to the catalog', catalogUp(h) && h.includes('Cart (0)'));
check('no console errors', logs.length === 0, logs.slice(0, 2).join(' | ').slice(0, 300));
const failed = checks.filter((c) => !c.ok);
console.log(`\n${checks.length} checks, ${failed.length} failed. Screenshots in ${outDir}`);
ws.close(); proc.kill();
process.exit(failed.length ? 1 : 0);
