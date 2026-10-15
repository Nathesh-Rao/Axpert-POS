// Admin "Export database" check (debug or release build with SKIP_ENTRY + DEMO_SEED):
//   flutter run -d web-server --web-port=8180 --web-hostname=127.0.0.1 --dart-define=SKIP_ENTRY=true --dart-define=DEMO_SEED=true
//   node --experimental-websocket tool/web_check/export_check.mjs http://127.0.0.1:8180/ <outDir> [width height]
// Opens Settings as admin (Demo#Admin1), clicks Export, confirms, waits for the
// browser download, then opens the downloaded file with the `sqlite3` CLI and
// prints its size, user_version, table count and a row count per table.
// Exit 1 on a console error, no download, or an unreadable file.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';

const [url, outDir = '/tmp/export_check', widthArg = '1280', heightArg = '720'] = process.argv.slice(2);
const width = Number(widthArg), height = Number(heightArg);
fs.rmSync(outDir, { recursive: true, force: true });
fs.mkdirSync(outDir + '/dl', { recursive: true });
const dlDir = fs.realpathSync(outDir + '/dl');
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const port = 9300 + Math.floor(Math.random() * 500);
const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, `--window-size=${width},${height}`, '--user-data-dir=/tmp/expchk-' + port, 'about:blank'], { stdio: 'ignore' });
let targets;
for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {} await sleep(200); }
const ws = new WebSocket(targets.find((t) => t.type === 'page').webSocketDebuggerUrl);
await new Promise((r) => (ws.onopen = r));
let id = 0; const pending = new Map(); const logs = []; const all = [];
ws.onmessage = (m) => {
  const d = JSON.parse(m.data);
  if (d.id && pending.has(d.id)) { pending.get(d.id)(d.result); pending.delete(d.id); }
  else if (d.method === 'Runtime.consoleAPICalled') { const t = d.params.args.map((a) => a.value ?? a.description).join(' '); all.push(t); if (['error', 'assert'].includes(d.params.type)) logs.push(t); }
  else if (d.method === 'Runtime.exceptionThrown') logs.push('EXCEPTION ' + (d.params.exceptionDetails.exception?.description ?? d.params.exceptionDetails.text));
  else if (d.method === 'Log.entryAdded' && d.params.entry.level === 'error') logs.push(d.params.entry.text);
};
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
const shot = async (n) => fs.writeFileSync(`${outDir}/${n}.png`, Buffer.from((await send('Page.captureScreenshot', { format: 'png' })).data, 'base64'));
const click = async (x, y) => { await send('Input.dispatchMouseEvent', { type: 'mouseMoved', x, y }); await send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 }); await send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 }); };
await send('Runtime.enable'); await send('Log.enable'); await send('Page.enable');
await send('Browser.setDownloadBehavior', { behavior: 'allow', downloadPath: dlDir, eventsEnabled: true });
await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
await send('Page.navigate', { url });
const t0 = Date.now();
while (Date.now() - t0 < 120000) { if (await send('Runtime.evaluate', { expression: "!!document.querySelector('flutter-view, flt-glass-pane')", returnByValue: true }).then((r) => r.result?.value)) break; await sleep(200); }
await sleep(15000);
await shot('1_start');
const steps = JSON.parse(process.env.EXPORT_CLICKS ?? '[]'); // [[x,y],...] after seeing 1_start.png (the debug server serves one page load, so no reload)
for (const [i, [x, y]] of steps.entries()) { await click(x, y); await sleep(2500); await shot(`2_click${i}`); }
await sleep(3000);
const files = fs.readdirSync(dlDir).filter((f) => f.endsWith('.db'));
console.log('downloads:', files);
let ok = files.length === 1 && logs.length === 0;
if (files.length) {
  const f = `${dlDir}/${files[0]}`;
  console.log('size bytes', fs.statSync(f).size);
  const q = (sql) => execFileSync('sqlite3', [f, sql]).toString().trim();
  console.log('integrity', q('PRAGMA integrity_check'), 'user_version', q('PRAGMA user_version'));
  const tables = q("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name").split('\n');
  console.log('tables', tables.length);
  for (const t of tables) console.log(' ', t, q(`SELECT count(*) FROM "${t}"`));
}
console.log('console errors:', logs.length); for (const l of logs) console.log(' ', l.slice(0, 300));
console.log(all.filter((l) => /\[audit\]/.test(l)).join('\n'));
ws.close(); proc.kill();
process.exit(ok ? 0 : 1);
