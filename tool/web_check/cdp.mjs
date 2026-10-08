// usage: node cdp.mjs <url> <outPrefix> '<json actions>'
// actions: {"wait":ms} {"click":[x,y]} {"type":"text"} {"key":"Enter"} {"shot":"name"} {"move":[x,y]}
import { spawn } from 'node:child_process';
import fs from 'node:fs';
const [url, out, actionsJson = '[]'] = process.argv.slice(2);
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const port = 9300 + Math.floor(Math.random() * 500);
const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, '--window-size=2124,1180', '--user-data-dir=/tmp/cdp-prof-' + port, 'about:blank'], { stdio: 'ignore' });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let targets;
for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {} await sleep(200); }
const page = targets.find((t) => t.type === 'page');
const ws = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((r) => (ws.onopen = r));
let id = 0; const pending = new Map(); const logs = [];
ws.onmessage = (m) => { const d = JSON.parse(m.data);
  if (d.id && pending.has(d.id)) { pending.get(d.id)(d.result); pending.delete(d.id); }
  else if (d.method === 'Runtime.consoleAPICalled') logs.push(`console.${d.params.type}: ` + d.params.args.map((a) => a.value ?? a.description).join(' '));
  else if (d.method === 'Runtime.exceptionThrown') logs.push('EXCEPTION: ' + (d.params.exceptionDetails.exception?.description ?? d.params.exceptionDetails.text));
  else if (d.method === 'Log.entryAdded') logs.push(`log.${d.params.entry.level}: ${d.params.entry.text} ${d.params.entry.url ?? ''}`); };
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
await send('Runtime.enable'); await send('Log.enable'); await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', { width: 2124, height: 1180, deviceScaleFactor: 1, mobile: false });
await send('Page.navigate', { url });
const shot = async (name) => { const r = await send('Page.captureScreenshot', { format: 'png' }); fs.writeFileSync(`${out}_${name}.png`, Buffer.from(r.data, 'base64')); };
for (const a of JSON.parse(actionsJson)) {
  if (a.wait) await sleep(a.wait);
  else if (a.shot) await shot(a.shot);
  else if (a.move) await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x: a.move[0], y: a.move[1] });
  else if (a.click) { const [x, y] = a.click; await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 }); await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 }); }
  else if (a.type) await send('Input.insertText', { text: a.type });
  else if (a.key) { await send('Input.dispatchKeyEvent', { type: 'keyDown', key: a.key, code: a.key, windowsVirtualKeyCode: a.vk ?? 0 }); await send('Input.dispatchKeyEvent', { type: 'keyUp', key: a.key, code: a.key, windowsVirtualKeyCode: a.vk ?? 0 }); }
}
console.log(logs.filter((l) => !/service worker|CPU-only|Injecting|Installing|Activated/.test(l)).join('\n') || '(no console output besides bootstrap)');
ws.close(); proc.kill();
