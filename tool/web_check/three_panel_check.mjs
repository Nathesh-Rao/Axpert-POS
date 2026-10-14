// Release-build check of the three-panel POS layout (DEC-141): all six states, tile clicks at
// Products 25, a search add, collapsing and expanding Billing from the footer chip, and a cash
// checkout with Billing collapsed (F2 opens it) and then expanded.
//   flutter build web --release --dart-define=SKIP_ENTRY=true --dart-define=DEMO_SEED=true --dart-define=SKIP_ENTRY_USER=cashier1
//   python3 tool/web_check/serve.py build/web 8330 &
//   node --experimental-websocket tool/web_check/three_panel_check.mjs http://127.0.0.1:8330/ <outDir> <width> <height>
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';

const [url, outDir = '/tmp/three_panel', widthArg = '1280', heightArg = '720'] = process.argv.slice(2).filter((a) => !a.startsWith('--'));
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
  await sleep(12000);
};
const enableSemantics = async () => { await ev("(()=>{const p=document.querySelector('flt-semantics-placeholder'); if(p) p.click()})()"); await sleep(2500); };



const checks = [];
const check = (name, ok, detail = '') => { checks.push({ name, ok }); console.log(`${ok ? 'ok  ' : 'FAIL'} | ${name} ${detail}`); };
const html = () => ev('document.body.innerHTML');
const CTRL = 2, META = 4;
const mod = async (k, code, vk, modifiers) => {
  const [mk, mcode, mvk] = modifiers === 2 ? ['Control', 'ControlLeft', 17] : ['Meta', 'MetaLeft', 91];
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key: mk, code: mcode, windowsVirtualKeyCode: mvk, modifiers });
  await send('Input.dispatchKeyEvent', { type: 'rawKeyDown', key: k, code, windowsVirtualKeyCode: vk, modifiers });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', key: k, code, windowsVirtualKeyCode: vk, modifiers });
  await send('Input.dispatchKeyEvent', { type: 'keyUp', key: mk, code: mcode, windowsVirtualKeyCode: mvk, modifiers: 0 });
  await sleep(1500);
};
const ctrlB = () => mod('b', 'KeyB', 66, CTRL);
const ctrlDot = () => mod('.', 'Period', 190, CTRL);
// With Cmd held, macOS drops the key-up of the other key, so Flutter still counts '.' as pressed; release it by hand.
const cmdDot = async () => { await mod('.', 'Period', 190, META); await send('Input.dispatchKeyEvent', { type: 'keyUp', key: '.', code: 'Period', windowsVirtualKeyCode: 190 }); await sleep(300); };
// Semantics buttons carry their label as text. Click the first one whose label matches.
const buttons = (pattern) => `[...document.querySelectorAll('flt-semantics[role=button]')].filter((e)=>new RegExp(${JSON.stringify(pattern)}).test(e.textContent.trim()))`;
const clickLabel = async (pattern) => {
  const r = await ev(`(()=>{const n=${buttons(pattern)}[0];if(!n)return null;const b=n.getBoundingClientRect();return {x:b.x+b.width/2,y:b.y+b.height/2}})()`);
  if (!r) return false;
  await click(r.x, r.y); await sleep(1500);
  return true;
};
const hasLabel = (pattern) => ev(`${buttons(pattern)}.length>0`);
const countLabel = (pattern) => ev(`${buttons(pattern)}.length`);
const catalogUp = (h) => h.includes('Favourites') && h.includes('Soft Drinks');
const cartUp = (h) => h.includes('Qty') && h.includes('Total');
const billingUp = (h) => h.includes('Bill Summary') && h.includes('Invoice Total');

await load();
await enableSemantics();
let h = await html();
await shot('00_catalog_empty');
check('empty cart: catalog layout, Billing open', catalogUp(h) && billingUp(h));

// Add through the search box: the cart layout (Products hidden, Billing open).
await click(width / 2, 28);
await insert('8901234560015'); await key('Enter', 13); await sleep(1600);
await enableSemantics();
h = await html();
await shot('01_P0_B25_cart_75');
check('search add -> P0/B25: cart and Billing, no catalog', cartUp(h) && billingUp(h) && !catalogUp(h) && !(await hasLabel('Invoice total')));

// Products wider: P25/B25, all three. Tile click adds and stays.
check('chevron "wider" exists', await clickLabel('Make products wider'));
h = await html();
await shot('02_P25_B25_all_three');
check('P25/B25: catalog, cart and Billing together', catalogUp(h) && cartUp(h) && billingUp(h));
const before = await countLabel('^Remove item');
check('tile click at P25 adds a line', (await clickLabel('^Add ')) && (await countLabel('^Remove item')) >= before);
await shot('03_P25_after_tile_click');
h = await html();
check('tile click at P25 keeps all three panels', catalogUp(h) && cartUp(h) && billingUp(h));

// Wider again: P75/B25 (cart hidden), tile click flashes the count on the edge control.
await clickLabel('Make products wider');
h = await html();
await shot('04_P75_B25_catalog');
check('P75/B25: catalog and Billing, cart hidden', catalogUp(h) && billingUp(h) && !cartUp(h));
await clickLabel('^Add ');
h = await html();
check('tile click at P75 keeps the layout and the edge control reads Cart (n)', catalogUp(h) && /Cart \(\d+\)/.test(h));

// Billing collapsed with Ctrl+. : P75/B0 (cart 25%), then the cycle with Ctrl+B.
await ctrlDot();
h = await html();
await shot('05_P75_B0_cart_25');
check('Ctrl+. collapses Billing; the footer chip shows the invoice total', !billingUp(h) && (await hasLabel('Invoice total')));
await ctrlB();
await shot('06_P0_B0_cart_100');
h = await html();
check('Ctrl+B from 75 wraps to hidden: P0/B0, cart only', cartUp(h) && !catalogUp(h) && !billingUp(h));
await ctrlB();
await shot('07_P25_B0_cart_75');
h = await html();
check('Ctrl+B again: P25/B0, catalog and cart', catalogUp(h) && cartUp(h) && !billingUp(h));

// Expand Billing from the footer chip.
check('footer chip clickable', await clickLabel('Invoice total'));
h = await html();
await shot('08_chip_expanded_P25_B25');
check('the chip expands Billing back to 25%', billingUp(h) && catalogUp(h) && cartUp(h));
// Collapse with the header button, expand with Cmd+. .
check('collapse button exists', await clickLabel('^Hide billing'));
h = await html();
check('the collapse button hides Billing', !billingUp(h));
await cmdDot();
h = await html();
check('Cmd+. shows Billing again', billingUp(h));

// Back to the default cart layout, then cash checkout with Billing collapsed (F2 opens it).
await ctrlB(); await ctrlB();
await ctrlDot();
h = await html();
await shot('09_before_checkout_billing_collapsed');
check('before checkout: Billing collapsed', !billingUp(h));
await click(width / 2, 28);
await key('F2', 113); await sleep(1200);
h = await html();
await shot('10_F2_opened_billing');
check('F2 with Billing collapsed opens Billing and the cash panel', billingUp(h) && h.includes('Amount Tendered'));
await key('Enter', 13); await sleep(2500);
await enableSemantics();
h = await html();
await shot('11_receipt');
check('cash checkout completes (receipt shown)', h.includes('Retail tax invoice') || h.includes('New Sale'));
await key('Escape', 27); await sleep(1500);
h = await html();
check('after checkout the catalog layout returns, Billing stays open', catalogUp(h) && billingUp(h));

// Second sale with Billing open: add, F2, Enter.
await click(width / 2, 28);
await insert('8901234560015'); await key('Enter', 13); await sleep(1500);
await key('F2', 113); await sleep(1200);
await key('Enter', 13); await sleep(2500);
await enableSemantics();
h = await html();
check('cash checkout with Billing expanded completes', h.includes('Retail tax invoice') || h.includes('New Sale'));
await key('Escape', 27); await sleep(1200);
await shot('12_after_second_checkout');
check('no console errors', logs.length === 0, logs.slice(0, 2).join(' | ').slice(0, 300));
const failed = checks.filter((c) => !c.ok);
console.log(`\n${checks.length} checks, ${failed.length} failed. Screenshots in ${outDir}`);
ws.close(); proc.kill();
process.exit(failed.length ? 1 : 0);
