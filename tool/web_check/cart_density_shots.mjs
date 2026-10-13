// Screenshots of the POS cart for the density comparison (BEFORE and AFTER).
//   flutter build web --release --dart-define=SKIP_ENTRY=true --dart-define=DEMO_SEED=true --dart-define=SKIP_ENTRY_USER=cashier1
//   python3 tool/web_check/serve.py build/web 8330 &
//   PREFIX=before node --experimental-websocket tool/web_check/cart_density_shots.mjs http://127.0.0.1:8330/ <outDir> <width> <height>
// Adds 13 scans (10 different products: a Buy 1 Get 1 promotion, a 20 % discount,
// three Tata Tea so the free-gift tier unlocks), shoots light and dark, and
// prints how many cart rows are fully inside the window. Dark mode is switched
// through the Settings dialog.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';

const [url, outDir = '/tmp/cart_density', widthArg = '1280', heightArg = '720'] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
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


const prefix = process.env.PREFIX ?? 'shot';
const MENU = [width - 32, 27];
await load();
await click(width / 2, 28);
const codes = ['8901234560000', '8901234560001', '8901234560002', '8901234560003', '8901234560004', '8901234560005', '8901234560006', '8901234560015', '8901234560015', '8901234560020', '8901234560011', '8901234560011', '8901234560011'];
for (const code of codes) { await insert(code); await key('Enter', 13); await sleep(700); }
await sleep(2500);
const tag = `${width}x${height}`;
await shot(`${prefix}_${tag}_light`);
await click(...MENU); await sleep(600);
await click(width - 116, 128); await sleep(900);
await click(width / 2 + 188, height / 2 - 20); await sleep(900);
await key('Escape', 27); await sleep(900);
await shot(`${prefix}_${tag}_dark`);
console.log(`shots ${prefix}_${tag}_light/dark, console errors: ${logs.length}`);
ws.close(); proc.kill(); process.exit(0);
