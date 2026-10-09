// Browser performance probe (S7). Headless Chrome over the DevTools protocol,
// no packages. Measures what a canvas app lets us see from outside: page-clock
// requestAnimationFrame gaps (a long gap = a blocked main thread = a janky
// frame), paint entries, Network bytes and the JS heap.
//
// usage: node --experimental-websocket tool/web_check/perf.mjs <url> <storage.json|-> [runs] [width height]
//   storage.json: {"flutter.axpert-sales": "...", ...} written into localStorage
//   BEFORE the app starts (so the cold start includes loading that data).
//
// Honest limits: headless Chrome draws with SwiftShader (software GL), so the
// numbers are pessimistic and machine specific; canvas content is not in the
// DOM, so "painted" means "the main thread was free again", not a pixel check.
import { spawn } from 'node:child_process';
import fs from 'node:fs';

const [url, storagePath = '-', runsArg = '3', widthArg = '1280', heightArg = '720'] = process.argv.slice(2);
const runs = Number(runsArg), width = Number(widthArg), height = Number(heightArg);
const storage = storagePath === '-' ? {} : JSON.parse(fs.readFileSync(storagePath, 'utf8'));
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const median = (a) => { const s = [...a].sort((x, y) => x - y); return s.length ? s[Math.floor(s.length / 2)] : NaN; };
const pct = (a, p) => { const s = [...a].sort((x, y) => x - y); return s.length ? s[Math.min(s.length - 1, Math.floor(s.length * p))] : NaN; };

async function session() {
  const port = 9300 + Math.floor(Math.random() * 500);
  const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, `--window-size=${width},${height}`, '--user-data-dir=/tmp/perf-prof-' + port + '-' + Date.now(), 'about:blank'], { stdio: 'ignore' });
  let targets;
  for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {} await sleep(200); }
  const page = targets.find((t) => t.type === 'page');
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((r) => (ws.onopen = r));
  let id = 0; const pending = new Map(); const net = { bytes: 0, requests: 0, byHost: {} }; const reqUrl = new Map();
  ws.onmessage = (m) => {
    const d = JSON.parse(m.data);
    if (d.id && pending.has(d.id)) { pending.get(d.id)(d.result); pending.delete(d.id); return; }
    if (d.method === 'Network.requestWillBeSent') reqUrl.set(d.params.requestId, d.params.request.url);
    if (d.method === 'Network.loadingFinished') {
      const u = reqUrl.get(d.params.requestId) ?? '';
      const host = u.startsWith('data:') ? 'data' : (u.split('/')[2] ?? '?');
      net.bytes += d.params.encodedDataLength; net.requests++;
      net.byHost[host] = (net.byHost[host] ?? 0) + d.params.encodedDataLength;
    }
  };
  const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
  const evalJs = async (expression) => (await send('Runtime.evaluate', { expression, returnByValue: true })).result?.value;
  await send('Runtime.enable'); await send('Page.enable'); await send('Network.enable'); await send('Performance.enable');
  await send('Network.setCacheDisabled', { cacheDisabled: true });
  await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
  const seed = `try{const d=${JSON.stringify(storage)};for(const k in d)localStorage.setItem(k,d[k])}catch(e){}`;
  const recorder = 'window.__f=[];(function l(t){window.__f.push(t);requestAnimationFrame(l)})(0);';
  await send('Page.addScriptToEvaluateOnNewDocument', { source: seed + recorder });
  const close = () => { try { ws.close(); } catch {} proc.kill(); };
  return { send, evalJs, net, close };
}

// time (ms, page clock) of the first screenshot that is clearly not blank
async function coldStart(s) {
  const t0 = Date.now();
  await s.send('Page.navigate', { url });
  let glass = null, painted = null;
  while (Date.now() - t0 < 60000) {
    if (glass === null && (await s.evalJs("!!document.querySelector('flt-glass-pane, flutter-view')"))) glass = Date.now() - t0;
    if (glass !== null) {
      const shot = await s.send('Page.captureScreenshot', { format: 'png' });
      if (shot.data.length > 60000) { painted = Date.now() - t0; break; }
    }
    await sleep(40);
  }
  const paint = await s.evalJs("JSON.stringify(performance.getEntriesByType('paint').map(p=>[p.name,Math.round(p.startTime)]))");
  return { glass, painted, paint: JSON.parse(paint ?? '[]') };
}

async function mark(s) { return await s.evalJs('performance.now()'); }
async function framesBetween(s, a, b) { return JSON.parse(await s.evalJs(`JSON.stringify(window.__f.filter(x=>x>=${a}&&x<=${b}))`) ?? '[]'); }
function gaps(f) { const g = []; for (let i = 1; i < f.length; i++) g.push(f[i] - f[i - 1]); return g; }
async function window_(s, t0, ms) {
  await sleep(ms);
  const f = await framesBetween(s, t0, t0 + ms);
  const g = gaps(f);
  return { frames: f.length, maxGap: Math.round(Math.max(0, ...g)), over50: g.filter((x) => x > 50).length, p95: Math.round(pct(g, 0.95)) };
}
async function click(s, x, y) {
  await s.send('Input.dispatchMouseEvent', { type: 'mousePressed', x, y, button: 'left', clickCount: 1 });
  await s.send('Input.dispatchMouseEvent', { type: 'mouseReleased', x, y, button: 'left', clickCount: 1 });
}
async function typeChar(s, ch) {
  await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key: ch, text: ch, unmodifiedText: ch });
  await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key: ch });
}
async function press(s, key, vk) {
  await s.send('Input.dispatchKeyEvent', { type: 'keyDown', key, code: key, windowsVirtualKeyCode: vk });
  await s.send('Input.dispatchKeyEvent', { type: 'keyUp', key, code: key, windowsVirtualKeyCode: vk });
}
const heap = async (s) => Math.round(((await s.send('Performance.getMetrics')).metrics.find((m) => m.name === 'JSHeapUsedSize')?.value ?? 0) / 1048576);

const result = { url, size: `${width}x${height}`, storageKeys: Object.keys(storage), cold: [], interactions: {} };

// ---- cold starts ----
for (let i = 0; i < runs; i++) {
  const s = await session();
  const c = await coldStart(s);
  await sleep(1500);
  result.cold.push({ ...c, heapMB: await heap(s), transferredMB: +(s.net.bytes / 1048576).toFixed(2), requests: s.net.requests, byHostKB: Object.fromEntries(Object.entries(s.net.byHost).map(([k, v]) => [k, Math.round(v / 1024)])) });
  s.close();
}

// ---- interactions in one session (after a settled start) ----
{
  const s = await session();
  await coldStart(s); await sleep(2500);
  const searchBox = [width * 0.5, 28];
  const nav = { products: [32, 170], customers: [32, 245], sales: [32, 320], pos: [32, 95] };
  const run = async (name, fn) => { const m = await heap(s); const r = await fn(); result.interactions[name] = { ...r, heapMB: await heap(s), heapBeforeMB: m }; };

  await run('typing "lays" in the search with dropdown (per key, worst of 4)', async () => {
    await click(s, ...searchBox); await sleep(300);
    const per = [];
    for (const ch of 'lays') { const t0 = await mark(s); await typeChar(s, ch); per.push(await window_(s, t0, 500)); await sleep(120); }
    return { perKeyMaxGapMs: per.map((p) => p.maxGap), worstMaxGapMs: Math.max(...per.map((p) => p.maxGap)), over50: per.reduce((a, p) => a + p.over50, 0) };
  });
  // clear the search for the next steps
  for (let i = 0; i < 4; i++) await press(s, 'Backspace', 8);
  await sleep(500);
  await run('scroll the catalog (60 wheel events, 16 ms apart)', async () => {
    const t0 = await mark(s);
    for (let i = 0; i < 60; i++) { await s.send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: width * 0.4, y: height * 0.65, deltaX: 0, deltaY: 120 }); await sleep(16); }
    return await window_(s, t0, 600);
  });
  await run('add 50 items by barcode + Enter (20 distinct products)', async () => {
    await click(s, ...searchBox); await sleep(300);
    const codes = Array.from({ length: 20 }, (_, i) => (i < 10 ? 8901234567890 + i : 8901234567800 + i - 10));
    const t0 = await mark(s); const per = [];
    for (let i = 0; i < 50; i++) {
      const code = String(codes[i % 20]); const a = await mark(s);
      await s.send('Input.insertText', { text: code }); await press(s, 'Enter', 13);
      await sleep(30); const b = await mark(s);
      per.push(b - a);
    }
    const w = await window_(s, t0, 800);
    const t1 = await mark(s);
    return { ...w, totalMs: Math.round(t1 - t0), perItemMedianMs: Math.round(median(per)), perItemMaxMs: Math.round(Math.max(...per)) };
  });
  for (const [name, xy] of [['products', nav.products], ['customers', nav.customers], ['sales', nav.sales]]) {
    await run(`open ${name} (sidebar click)`, async () => {
      const t0 = await mark(s); await click(s, ...xy);
      return await window_(s, t0, 1500);
    });
    await sleep(500);
  }
  await run('scroll the open Sales table (60 wheel events)', async () => {
    const t0 = await mark(s);
    for (let i = 0; i < 60; i++) { await s.send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: width * 0.4, y: height * 0.6, deltaX: 0, deltaY: 400 }); await sleep(16); }
    return await window_(s, t0, 600);
  });
  s.close();
}

const med = (k) => Math.round(median(result.cold.map((c) => c[k]).filter((x) => x !== null)));
result.summary = { coldGlassPaneMedianMs: med('glass'), coldPaintedMedianMs: med('painted'), coldHeapMB: Math.round(median(result.cold.map((c) => c.heapMB))) };
console.log(JSON.stringify(result, null, 1));
