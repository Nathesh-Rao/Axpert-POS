// Release-build check of the cart-first desktop layout.
//   flutter build web --release --dart-define=SKIP_ENTRY=true --dart-define=DEMO_SEED=true --dart-define=SKIP_ENTRY_USER=cashier1
//   python3 tool/web_check/serve.py build/web 8330 &
//   node --experimental-websocket tool/web_check/cart_first_check.mjs http://127.0.0.1:8330/ <outDir> [width height]
// 13 scans with the Products panel collapsed (Buy 1 Get 1, a discount, the free-gift tier),
// Ctrl+B and Cmd+B, Escape, hold, recall and a cash checkout.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';

const [url, outDir = '/tmp/cart_first', widthArg = '1280', heightArg = '720'] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
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
const mod = async (k, code, vk, modifiers) => {
  // The framework tracks the pressed keys itself, so the modifier key goes down first.
  const [mk, mcode, mvk] = modifiers === 2 ? ['Control', 'ControlLeft', 17] : ['Meta', 'MetaLeft', 91];
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key: mk, code: mcode, windowsVirtualKeyCode: mvk, modifiers });
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key: k, code, windowsVirtualKeyCode: vk, modifiers });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', key: k, code, windowsVirtualKeyCode: vk, modifiers });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', key: mk, code: mcode, windowsVirtualKeyCode: mvk, modifiers: 0 });
  await sleep(900);
};
const html = () => ev('document.body.innerHTML');
const CTRL = 2, META = 4;

await load();
await enableSemantics();
let h = await html();
check('starts with the Products panel collapsed and an empty cart state', h.includes('No items yet') && !h.includes('Soft Drinks'));
await click(width / 2, 28);
const codes = ['8901234560000', '8901234560001', '8901234560002', '8901234560003', '8901234560004', '8901234560005', '8901234560006', '8901234560015', '8901234560015', '8901234560020', '8901234560011', '8901234560011', '8901234560011'];
for (const code of codes) { await insert(code); await key('Enter', 13); await sleep(700); }
await sleep(2500);
await shot('01_after_13_scans');
h = await html();
check('13 scans with the panel collapsed: the cart has its rows', h.includes('Oreo Biscuit 120g') && h.includes('Tata Tea Gold 250g'));
check('Buy 1 Get 1 and the free-gift tier show in the rows', h.includes('Oreo Buy 1 Get 1 · saved') && h.includes('Free item Dairy Milk 40g unlocked') && h.includes('Locked free item Dove Soap 100g'));
check('the one-line footer shows the totals', h.includes('13.000'));

await mod('b', 'KeyB', 66, CTRL);
await shot('02_panel_open_ctrl_b');
h = await html();
check('Ctrl+B opens the Products panel', h.includes('Soft Drinks') || h.includes('Favourites'));
await key('Escape', 27); await sleep(900);
h = await html();
check('Escape closes the panel', !h.includes('Soft Drinks'));
await mod('b', 'KeyB', 66, META);
h = await html();
check('Cmd+B opens it again', h.includes('Soft Drinks') || h.includes('Favourites'));
await mod('b', 'KeyB', 66, CTRL);
h = await html();
check('Ctrl+B closes it', !h.includes('Soft Drinks'));

await key('F4', 115); await sleep(1500);
await shot('03_after_hold');
h = await html();
check('F4 holds the bill: the cart is empty again', h.includes('No items yet'));
await key('F5', 116); await sleep(1200);
await shot('04_recall_dialog');
h = await html();
check('F5 lists the held bill', h.includes('Held bills'));
await click(width / 2, height / 2 + 44); await sleep(1500);
await shot('05_after_recall');
h = await html();
check('recall restores the lines', h.includes('Oreo Biscuit 120g'));

await key('F2', 113); await sleep(900);
await key('Enter', 13); await sleep(2500);
await shot('06_receipt');
h = await html();
check('F2 + Enter completes a cash sale and opens the receipt', h.includes('Retail tax invoice') && h.includes('Cashier: Chitra Cashier'));
check('no console errors', logs.length === 0, logs.slice(0, 2).join(' | ').slice(0, 300));
const failed = checks.filter((c) => !c.ok);
console.log(`\n${checks.length} checks, ${failed.length} failed. Screenshots in ${outDir}`);
ws.close(); proc.kill();
process.exit(failed.length ? 1 : 0);
