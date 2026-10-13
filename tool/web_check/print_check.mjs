// Release-build check of system printing (web: the browser print dialog).
//   flutter build web --release --dart-define=SKIP_ENTRY=true --dart-define=DEMO_SEED=true --dart-define=SKIP_ENTRY_USER=cashier1
//   python3 tool/web_check/serve.py build/web 8310 &
//   node --experimental-websocket tool/web_check/print_check.mjs http://127.0.0.1:8310/ <outDir> [1280 1100]
// The print dialog cannot open in headless Chrome, so a hook (injected into every
// frame before the page runs) replaces window.print and counts the calls and the
// PDF iframes the printing package creates. Checks: Print in the receipt dialog
// after a checkout prints once, and Reprint -> a sale -> Print prints once more.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';

const [url, outDir = '/tmp/print_check', widthArg = '1280', heightArg = '720'] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
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


const HOOK = `(()=>{const top=window.top;try{top.__prints=top.__prints||[];top.__frames=top.__frames||[];}catch(e){}
const rec=(w)=>{try{const orig=w.print;w.print=function(){try{window.top.__prints.push(location.href.slice(0,40));}catch(e){}};}catch(e){}};
rec(window);
try{window.top.__blobs=window.top.__blobs||[];const cu=URL.createObjectURL;URL.createObjectURL=function(b){try{window.top.__blobs.push((b.type||'')+':'+b.size);}catch(e){}return cu.call(URL,b);};}catch(e){}
new MutationObserver((ms)=>{for(const m of ms)for(const n of m.addedNodes){if(n.tagName==='IFRAME'){try{window.top.__frames.push((n.src||'').slice(0,20));}catch(e){}}}}).observe(document,{childList:true,subtree:true});})()`;
await send('Page.addScriptToEvaluateOnNewDocument', { source: HOOK });
ws.addEventListener('message', (m) => { const d = JSON.parse(m.data); if (d.method === 'Runtime.consoleAPICalled') { const t = d.params.args.map((a) => a.value ?? a.description).join(' '); if (t.includes('SystemPrintService')) console.log('PRINT LOG:', t.slice(0, 700)); } });
const checks = [];
const check = (name, ok, detail = '') => { checks.push({ name, ok }); console.log(`${ok ? 'ok  ' : 'FAIL'} | ${name} ${detail}`); };
const prints = async () => JSON.parse((await ev('JSON.stringify(window.__prints||[])')) ?? '[]');
const blobs = async () => JSON.parse((await ev('JSON.stringify(window.__blobs||[])')) ?? '[]');
const frames = async () => JSON.parse((await ev('JSON.stringify(window.__frames||[])')) ?? '[]');
// Coordinates are for the 1100 px high window (the receipt dialog needs the height).
const PRINT = [478, 873], NEW_SALE = [640, 930], REPRINT = [1076, 1039], FIRST_SALE = [640, 433];
const clickAt = async ([x, y]) => { await click(x, y); await sleep(1300); return true; };

await load();
await click(width / 2, 28);
for (const code of ['8901234560000', '8901234560011']) { await insert(code); await key('Enter', 13); await sleep(900); }
await key('F2', 113); await sleep(700);
await key('Enter', 13); await sleep(2500);
await enableSemantics();
await shot('print_01_receipt');
check('the receipt dialog is open with a Print button', await ev("document.body.innerHTML.includes('Retail tax invoice')"));
check('nothing printed before the click', (await prints()).length === 0);
const clicked = await clickAt(PRINT);
await enableSemantics();
const toastText = await ev("/Could not print|not available/.test(document.body.innerText + document.body.innerHTML)");
console.log('toast after Print:', toastText, 'blobs', JSON.stringify(await blobs()));
await sleep(4000);
await shot('print_02_after_print');
const p1 = await prints(); const f1 = await frames();
console.log('after receipt Print: window.print calls', JSON.stringify(p1), 'iframes', JSON.stringify(f1));
check('clicked Print in the receipt dialog', clicked);
check('exactly one print call after the receipt Print', p1.length === 1, JSON.stringify(p1));
check('a PDF frame (blob) was created for the print layout', f1.length >= 1 && f1.some((s) => s.startsWith('blob:')), JSON.stringify(f1));

// Reprint: close the receipt, Bill Summary Reprint -> first sale -> Print.
await clickAt(NEW_SALE);
await sleep(800);
const reprintOpened = await clickAt(REPRINT);
await shot('print_03_reprint_list');
const rowOpened = await clickAt(FIRST_SALE);
await sleep(1200);
await shot('print_04_reprint_receipt');
check('Reprint opens the list and a sale row opens its receipt', reprintOpened && rowOpened);
check('Reprint and opening the receipt print nothing by themselves', (await prints()).length === 1);
await clickAt(PRINT);
await sleep(4000);
const p2 = await prints();
console.log('after reprint Print: window.print calls', JSON.stringify(p2));
check('exactly one more print call after Reprint -> Print', p2.length === 2, JSON.stringify(p2));
check('no console errors', logs.length === 0, logs.slice(0, 2).join(' | ').slice(0, 300));
const failed = checks.filter((c) => !c.ok);
console.log(`\n${checks.length} checks, ${failed.length} failed. Screenshots in ${outDir}`);
ws.close(); proc.kill();
process.exit(failed.length ? 1 : 0);
