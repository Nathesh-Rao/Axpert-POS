// Start-up phase table for the release web build (D3, measurement only).
//
// Build with the timeline on (default builds print nothing):
//   flutter build web --release --dart-define=STARTUP_TIMELINE=true
//   python3 tool/web_check/serve.py build/web 8098 &
//   node --experimental-websocket tool/web_check/startup_check.mjs http://127.0.0.1:8098/ [runs=5] [width=1280] [height=720]
//
// Each run uses a fresh Chrome profile: "cold" = first start (empty storage:
// database created, copies done), "warm" = second load in the same profile.
// The app prints one `[startup] {json}` console line after the first frame is
// rasterized. Prints a median table and an estimate WITHOUT MockDelay (the
// simulated 200 to 500 ms latency of the Mock repositories; the Drift
// repositories have none): estimate = duration - the delay MockDelay recorded
// inside that phase. Headless Chrome draws with SwiftShader (pessimistic) and
// the machine is shared with the build server: use it to compare, not as a
// promise for real hardware.
import { spawn } from 'node:child_process';

const [url, runsArg = '5', widthArg = '1280', heightArg = '720'] = process.argv.slice(2);
const runs = Number(runsArg), width = Number(widthArg), height = Number(heightArg);
const CH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const median = (a) => { const s = [...a].sort((x, y) => x - y); return s.length ? s[Math.floor(s.length / 2)] : NaN; };

async function launch() {
  const port = 9300 + Math.floor(Math.random() * 500);
  const profile = '/tmp/startup-prof-' + port + '-' + Date.now();
  const proc = spawn(CH, ['--headless=new', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist', `--remote-debugging-port=${port}`, `--window-size=${width},${height}`, '--user-data-dir=' + profile, 'about:blank'], { stdio: 'ignore' });
  return { port, proc };
}

async function loadOnce(port) {
  let targets;
  for (let i = 0; i < 50; i++) { try { targets = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); if (targets.length) break; } catch {} await sleep(200); }
  const ws = new WebSocket(targets.find((t) => t.type === 'page').webSocketDebuggerUrl);
  await new Promise((r) => (ws.onopen = r));
  let id = 0; const pending = new Map(); let line = null; const errors = [];
  ws.onmessage = (m) => {
    const d = JSON.parse(m.data);
    if (d.id && pending.has(d.id)) { pending.get(d.id)(d.result); pending.delete(d.id); return; }
    if (d.method === 'Runtime.consoleAPICalled') {
      const text = d.params.args.map((a) => a.value ?? a.description ?? '').join(' ');
      if (text.startsWith('[startup] ')) line = text.slice(10);
      else if (d.params.type === 'error') errors.push(text.slice(0, 200));
    }
    if (d.method === 'Runtime.exceptionThrown') errors.push(JSON.stringify(d.params.exceptionDetails).slice(0, 200));
  };
  const send = (method, params = {}) => new Promise((r) => { const i = ++id; pending.set(i, r); ws.send(JSON.stringify({ id: i, method, params })); });
  await send('Runtime.enable'); await send('Page.enable'); await send('Network.enable');
  await send('Network.setCacheDisabled', { cacheDisabled: true });
  await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: false });
  // Runtime.enable replays the console of the page that is still open (the
  // previous load): forget it, only messages after the navigation count.
  await sleep(200); line = null; errors.length = 0;
  await send('Page.navigate', { url });
  const t0 = Date.now();
  while (line === null && Date.now() - t0 < 60000) await sleep(100);
  const origin = (await send('Runtime.evaluate', { expression: 'performance.timeOrigin', returnByValue: true })).result?.value;
  ws.close();
  if (line === null) return { error: 'no [startup] line (build without --dart-define=STARTUP_TIMELINE=true?)', errors };
  const data = JSON.parse(line);
  return { ...data, bootMs: Math.round(data.epoch_at_start_ms - origin), errors };
}

const cold = [], warm = [];
for (let i = 0; i < runs; i++) {
  const { port, proc } = await launch();
  try {
    const a = await loadOnce(port); await sleep(1500);
    const b = await loadOnce(port);
    if (a.error || b.error) { console.log('run', i, a.error ?? b.error); }
    else { cold.push(a); warm.push(b); }
  } finally { proc.kill(); }
}
if (!cold.length) { console.log('no usable runs'); process.exit(1); }

const ms = (us) => us / 1000;
function table(label, list) {
  const names = [...new Set(list.flatMap((r) => r.phases.map((p) => p.name)))];
  // keep first-seen order
  const order = list[0].phases.map((p) => p.name);
  for (const n of names) if (!order.includes(n)) order.push(n);
  const rows = order.map((name) => {
    const ph = list.map((r) => r.phases.find((p) => p.name === name)).filter(Boolean);
    const at = median(ph.map((p) => ms(p.at)));
    const dur = ph[0].dur === undefined ? null : median(ph.map((p) => ms(p.dur)));
    const mock = median(list.map((r) => r.mock_delay_ms?.[name] ?? 0));
    return { name, at, dur, mock, n: ph.length };
  });
  console.log(`\n${label} (${list.length} runs, median ms; "at" = ms since main start, "no mock" = duration minus recorded MockDelay)`);
  console.log('phase'.padEnd(44) + 'at'.padStart(8) + 'duration'.padStart(10) + 'MockDelay'.padStart(11) + 'no mock'.padStart(9));
  for (const r of rows) {
    console.log(r.name.padEnd(44) + String(Math.round(r.at)).padStart(8) + (r.dur === null ? '-' : String(Math.round(r.dur))).padStart(10) + (r.mock ? String(Math.round(r.mock)) : '-').padStart(11) + (r.dur === null || !r.mock ? '-' : String(Math.round(r.dur - r.mock))).padStart(9));
  }
  // estimate of the first frame without MockDelay: remove the MockDelay on the critical path
  const get = (n, k) => rows.find((r) => r.name === n)?.[k] ?? 0;
  const parallel = ['load products', 'load customers', 'load sales', 'load held bills'];
  const measuredLoad = get('loadData (all)', 'dur');
  const estLoad = get('load settings', 'dur') - get('load settings', 'mock')
    + Math.max(...parallel.map((n) => get(n, 'dur') - get(n, 'mock')))
    + get('load cart', 'dur') - get('load cart', 'mock');
  const first = get('first frame rasterized', 'at');
  const boot = median(list.map((r) => r.bootMs));
  console.log(`JS/engine boot before main (timeOrigin to main start): ${Math.round(boot)} ms`);
  console.log(`loadData: measured ${Math.round(measuredLoad)} ms, estimate without MockDelay ${Math.round(estLoad)} ms (settings + slowest parallel load + cart, MockDelay removed)`);
  console.log(`first frame rasterized: measured ${Math.round(first)} ms after main start (${Math.round(first + boot)} ms after page start), estimate without MockDelay ${Math.round(first - (measuredLoad - estLoad))} ms (${Math.round(first - (measuredLoad - estLoad) + boot)} ms after page start)`);
  console.log('console errors:', list.reduce((a, r) => a + r.errors.length, 0));
}
table('COLD start (empty profile)', cold);
table('WARM start (second load, same profile)', warm);
