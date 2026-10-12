// Needs a build/run WITH --dart-define=SKIP_ENTRY=true (starts on the POS page, no splash/login); see entry.mjs.
// First-frame theme check for the Drift settings (D1): with dark=true saved,
// a reload must not paint a light Flutter frame.
//   python3 tool/web_check/serve.py build/web 8300 &
//   node --experimental-websocket tool/web_check/theme_check.mjs http://127.0.0.1:8300/ <outDir>
// Load 1 seeds LocalStore dark=true (shared_preferences key flutter.axpert-dark)
// so the app copies it into Drift. Before load 2 the LocalStore key is removed,
// so a dark load 2 proves the value came from Drift. Load 2 is screenshotted
// every ~40 ms; PNGs are decoded here and the luminance of a few points is
// listed per sample (t, * = view tag present) and classified: unpainted page, dark frame, light frame. Exit 1 on any light frame.
import { spawn } from 'node:child_process';
import fs from 'node:fs';
import zlib from 'node:zlib';

const [url, outDir = '/tmp/theme_check'] = process.argv.slice(2);
fs.mkdirSync(outDir, { recursive: true });
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const port = 9300 + Math.floor(Math.random() * 500);
const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, '--window-size=1280,720', '--user-data-dir=/tmp/themechk-' + port, 'about:blank'], { stdio: 'ignore' });
let targets;
for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {} await sleep(200); }
const ws = new WebSocket(targets.find((t) => t.type === 'page').webSocketDebuggerUrl);
await new Promise((r) => (ws.onopen = r));
let id = 0; const pending = new Map(); const logs = [];
ws.onmessage = (m) => {
  const d = JSON.parse(m.data);
  if (d.id && pending.has(d.id)) { pending.get(d.id)(d.result); pending.delete(d.id); }
  else if (d.method === 'Runtime.exceptionThrown') logs.push('EXCEPTION ' + (d.params.exceptionDetails.exception?.description ?? d.params.exceptionDetails.text));
  else if (d.method === 'Runtime.consoleAPICalled' && d.params.type === 'error') logs.push(d.params.args.map((a) => a.value ?? a.description).join(' '));
};
const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
const ev = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true })).result?.value;
await send('Runtime.enable'); await send('Page.enable');
await send('Emulation.setDeviceMetricsOverride', { width: 1280, height: 720, deviceScaleFactor: 1, mobile: false });

function centreLuma(b64) {
  const buf = Buffer.from(b64, 'base64');
  let o = 8, w = 0, h = 0, bpp = 4; const idat = [];
  while (o < buf.length) {
    const len = buf.readUInt32BE(o), type = buf.toString('latin1', o + 4, o + 8);
    if (type === 'IHDR') { w = buf.readUInt32BE(o + 8); h = buf.readUInt32BE(o + 12); bpp = buf[o + 17] === 2 ? 3 : 4; }
    if (type === 'IDAT') idat.push(buf.subarray(o + 8, o + 8 + len));
    o += 12 + len;
  }
  const raw = zlib.inflateSync(Buffer.concat(idat)); const stride = w * bpp; const px = Buffer.alloc(h * stride);
  for (let y = 0; y < h; y++) {
    const f = raw[y * (stride + 1)];
    for (let x = 0; x < stride; x++) {
      const v = raw[y * (stride + 1) + 1 + x];
      const a = x >= bpp ? px[y * stride + x - bpp] : 0, b = y ? px[(y - 1) * stride + x] : 0, c = x >= bpp && y ? px[(y - 1) * stride + x - bpp] : 0;
      const p = f === 0 ? 0 : f === 1 ? a : f === 2 ? b : f === 3 ? (a + b) >> 1 : (() => { const pp = a + b - c, pa = Math.abs(pp - a), pb = Math.abs(pp - b), pc = Math.abs(pp - c); return pa <= pb && pa <= pc ? a : pb <= pc ? b : c; })();
      px[y * stride + x] = (v + p) & 255;
    }
  }
  // Average of a few points across the page (header strip, middle, bottom).
  const pts = [[0.5, 0.5], [0.3, 0.3], [0.7, 0.8], [0.9, 0.1]]; let sum = 0;
  for (const [fx, fy] of pts) { const i = Math.floor(fy * h) * stride + Math.floor(fx * w) * bpp; sum += 0.2126 * px[i] + 0.7152 * px[i + 1] + 0.0722 * px[i + 2]; }
  return Math.round(sum / pts.length);
}

// Load 1: seed LocalStore (only when empty) so the app copies dark=true into Drift.
await send('Page.addScriptToEvaluateOnNewDocument', { source: `try{if(!localStorage.getItem('flutter.axpert-dark')&&!sessionStorage.getItem('seeded')){localStorage.setItem('flutter.axpert-dark','"true"');sessionStorage.setItem('seeded','1')}}catch(e){}` });
await send('Page.navigate', { url });
for (let i = 0; i < 300; i++) { if (await ev("!!document.querySelector('flutter-view, flt-glass-pane')")) break; await sleep(100); }
await sleep(5000);
const load1 = centreLuma((await send('Page.captureScreenshot', { format: 'png' })).data);
// Remove the LocalStore copy so load 2 can only get dark from Drift.
await ev("localStorage.removeItem('flutter.axpert-dark'); sessionStorage.setItem('seeded','1'); 1");
const keysLeft = await ev("JSON.stringify(Object.keys(localStorage).filter(k=>k.includes('axpert')))");

// Load 2: sample frames from navigation until well after the view appears.
const samples = []; const t0 = Date.now();
await send('Page.navigate', { url });
let viewSeenAt = null;
while (Date.now() - t0 < 25000) {
  const view = await ev("!!document.querySelector('flutter-view, flt-glass-pane')").catch(() => false);
  if (view && viewSeenAt === null) viewSeenAt = Date.now() - t0;
  const shot = await send('Page.captureScreenshot', { format: 'png' }).catch(() => null);
  if (shot?.data) samples.push({ t: Date.now() - t0, view: !!view, luma: centreLuma(shot.data) });
  if (viewSeenAt !== null && Date.now() - t0 > viewSeenAt + 4000) break;
  await sleep(40);
}
const final = await send('Page.captureScreenshot', { format: 'png' });
fs.writeFileSync(`${outDir}/theme_check_load2.png`, Buffer.from(final.data, 'base64'));
const dbg = samples.map((s) => `${s.t}ms${s.view ? '*' : ''}:${s.luma}`).join(' ');
// 255 = the unpainted page (the flutter-view tag exists from the first
// instant, before runApp), < 100 = dark Flutter frame, anything between
// (the light theme paints about 252) = a light Flutter frame, i.e. a flash.
const blank = samples.filter((s) => s.luma === 255), dark = samples.filter((s) => s.luma < 100), light = samples.filter((s) => s.luma >= 100 && s.luma < 255);
const firstDarkAt = dark[0]?.t ?? null;
console.log('unpainted samples:', blank.length, '| dark frames:', dark.length, '| light frames:', light.length, '| first dark frame at', firstDarkAt, 'ms (view tag seen at', viewSeenAt, 'ms)');
console.log('console errors:', logs.length, logs.slice(0, 2).join(' | ').slice(0, 200));
const ok = load1 < 100 && dark.length > 0 && light.length === 0 && logs.length === 0;
console.log(ok ? 'THEME CHECK OK (first painted frame is dark, no light flash)' : 'THEME CHECK FAILED');
ws.close(); proc.kill();
process.exit(ok ? 0 : 1);
