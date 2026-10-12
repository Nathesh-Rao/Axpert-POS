// Release screenshots of the store and counter picker (admin has two stores).
//   flutter build web --release --dart-define=DEMO_SEED=true   (no SKIP_ENTRY)
//   python3 tool/web_check/serve.py build/web 8320 &
//   node --experimental-websocket tool/web_check/picker_shots.mjs http://127.0.0.1:8320/ <outDir> [light|dark] [width height]
import { spawn } from 'node:child_process';
import fs from 'node:fs';
const [url, outDir = '/tmp/picker', mode = 'light', w = '1280', h = '720'] = process.argv.slice(2);
fs.mkdirSync(outDir, { recursive: true });
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const port = 9300 + Math.floor(Math.random() * 500);
const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, `--window-size=${w},${h}`, '--user-data-dir=/tmp/pickchk-' + port, 'about:blank'], { stdio: 'ignore' });
let t;
for (let i = 0; i < 50; i++) { try { t = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (t.length) break; } catch {} await sleep(200); }
const ws = new WebSocket(t.find((x) => x.type === 'page').webSocketDebuggerUrl);
await new Promise((r) => (ws.onopen = r));
let id = 0; const pending = new Map(); const logs = [];
ws.onmessage = (m) => { const d = JSON.parse(m.data); if (d.id && pending.has(d.id)) { pending.get(d.id)(d.result); pending.delete(d.id); } else if (d.method === 'Runtime.exceptionThrown') logs.push('EXC ' + d.params.exceptionDetails.text); else if (d.method === 'Runtime.consoleAPICalled' && d.params.type === 'error') logs.push(d.params.args.map((a) => a.value ?? a.description).join(' ')); };
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
const key = async (k, vk) => { await send('Input.dispatchKeyEvent', { type: 'keyDown', key: k, code: k, windowsVirtualKeyCode: vk }); await send('Input.dispatchKeyEvent', { type: 'keyUp', key: k, code: k, windowsVirtualKeyCode: vk }); };
await send('Runtime.enable'); await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', { width: Number(w), height: Number(h), deviceScaleFactor: 1, mobile: false });
if (mode === 'dark') await send('Page.addScriptToEvaluateOnNewDocument', { source: "try{localStorage.setItem('flutter.axpert-dark',JSON.stringify('true'))}catch(e){}" });
await send('Page.navigate', { url });
await sleep(14000); // load, seed, splash
const shot = async (n) => { const r = await send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync(`${outDir}/${n}.png`, Buffer.from(r.data, 'base64')); };
await shot(`${mode}_1_login`);
await send('Input.insertText', { text: 'admin' }); await key('Tab', 9); await send('Input.insertText', { text: 'Demo#Admin1' }); await key('Enter', 13);
await sleep(3500);
await shot(`${mode}_2_picker`);
console.log('console errors:', logs.length, logs.slice(0, 2).join(' | '));
ws.close(); proc.kill();
