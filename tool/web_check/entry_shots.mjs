// Entry flow screenshots from a RELEASE build served WITHOUT SKIP_ENTRY:
//   flutter build web --release
//   python3 tool/web_check/serve.py build/web 8098 &
//   node --experimental-websocket tool/web_check/entry_shots.mjs http://127.0.0.1:8098/ <outDir> [width height]
// Headless Chrome (SwiftShader) needs several seconds to load, so the script
// polls screenshots until the first painted frame, then times everything from
// there: splash mid-animation, the logo hop, the login, a click on Sign In
// (loading state) and the landing page. Prints the console and overflow count.
import { spawn } from 'node:child_process';
import fs from 'node:fs';

const [url, outDir = '/tmp/entry_shots', widthArg = '1280', heightArg = '720'] = process.argv.slice(2);
const width = Number(widthArg), height = Number(heightArg);
fs.mkdirSync(outDir, { recursive: true });
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const port = 9300 + Math.floor(Math.random() * 500);
const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, `--window-size=${width},${height}`, '--user-data-dir=' + fs.mkdtempSync('/tmp/entry_shots_profile_'), 'about:blank'], { stdio: 'ignore' });
let targets;
for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {} await sleep(200); }
const ws = new WebSocket(targets.find((t) => t.type === 'page').webSocketDebuggerUrl);
await new Promise((r) => (ws.onopen = r));
let id = 0; const pending = new Map(); const logs = [];
ws.onmessage = (m) => {
  const d = JSON.parse(m.data);
  if (d.id && pending.has(d.id)) { pending.get(d.id)(d.result); pending.delete(d.id); }
  else if (d.method === 'Runtime.consoleAPICalled') logs.push(`${d.params.type}: ${d.params.args.map((a) => a.value ?? a.description).join(' ')}`);
  else if (d.method === 'Runtime.exceptionThrown') logs.push('exception: ' + (d.params.exceptionDetails.exception?.description ?? d.params.exceptionDetails.text));
};
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
await send('Runtime.enable'); await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
const shot = async (name) => { const r = await send('Page.captureScreenshot', { format: 'png' }); if (!r?.data) return 0; const b = Buffer.from(r.data, 'base64'); fs.writeFileSync(`${outDir}/${name}.png`, b); return b.length; };
const click = async (x, y) => { await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y }); await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 }); await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 }); };
const key = async (k, vk) => { await send('Input.dispatchKeyEvent', { type: 'keyDown', key: k, code: k, windowsVirtualKeyCode: vk }); await send('Input.dispatchKeyEvent', { type: 'keyUp', key: k, code: k, windowsVirtualKeyCode: vk }); };

const win = await send('Browser.getWindowForTarget');
if (win?.windowId) await send('Browser.setWindowBounds', { windowId: win.windowId, bounds: { width, height: height + 120 } });
await send('Page.navigate', { url });
await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
const t0 = Date.now();
let size = 0;
while (Date.now() - t0 < 60000) { await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false }); size = await shot('0_poll'); if (size > 20000) break; await sleep(150); }
const painted = Date.now();
console.log(`first painted frame after ${painted - t0} ms; viewport`, (await send('Runtime.evaluate', { expression: 'innerWidth+"x"+innerHeight+"@"+devicePixelRatio', returnByValue: true })).result?.value);
const vp = (await send('Runtime.evaluate', { expression: 'innerWidth+"x"+innerHeight', returnByValue: true })).result?.value;
if (vp !== `${width}x${height}`) { console.log(`viewport ${vp}, not ${width}x${height}: run again`); proc.kill(); process.exit(2); }
await sleep(300); await shot('1_splash_mid');
await sleep(2900); await shot('2_login');
await send('Input.insertText', { text: 'cashier' }); await key('Tab', 9); await send('Input.insertText', { text: 'demo-password' });
await sleep(200); await shot('3_login_filled');
await key('Enter', 13);
await sleep(250); await shot('4_loading');
await sleep(2600); await shot('5_landing');
console.log('console:', logs.length ? logs.slice(0, 8).join(' | ') : '(clean)');
proc.kill();
process.exit(0);
