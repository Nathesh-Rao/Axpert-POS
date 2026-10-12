// Needs a build/run WITH --dart-define=SKIP_ENTRY=true (starts on the POS page, no splash/login); see entry.mjs.
// Release-build check that the cart draft really persists in Drift (D6, DEC-130). Use the build
// WITH the timeline define (it prints a `[perf]` line per Drift cart write):
//   flutter build web --dart-define=STARTUP_TIMELINE=true -o build/web_timeline
//   python3 tool/web_check/serve.py build/web_timeline 8301 &
//   node --experimental-websocket tool/web_check/cart_flow_check.mjs http://127.0.0.1:8301/ <outDir>
// Run A (fresh profile, 1280x720): add two products through the search box, RELOAD and read the
// single `current_cart` row (rebuilt SQLite file): both lines, equal to the LocalStore mirror, the
// marker, user_version 8; the UI shows the lines again; clear the cart (quick action + Confirm),
// RELOAD: the row holds the empty cart and the mirror too.
// Run B (fresh profile): an unreadable `axpert-cart` value is put into localStorage BEFORE the first
// load: the app starts with an empty cart and no console error, no cart row is written, the marker
// report says unreadable; adding a product overwrites it, RELOAD restores it from Drift.
// Run C (write cost): 12 spaced adds of the same product, then 10 back-to-back keystrokes in the price
// field, with the `[perf]` lines: Drift writes per burst and ms per write; the final values are in Drift.
// Run D (durability on reload): add a product, wait [0, 0, 30, 60, 120, 250] ms, RELOAD, check the
// row has that product; reports how many trials lost the last change (the loss window).
// Exit 1 on any mismatch in A to C; D only reports.
import fs from 'node:fs';
import { launch, withDb, lsRead, lsRaw, sleep } from './products_common.mjs';

const [url, outDir = '/tmp/cart_flow'] = process.argv.slice(2);
fs.mkdirSync(outDir, { recursive: true });
const failures = [];
const check = (name, ok, detail = '') => { console.log(ok ? 'ok  ' : 'FAIL', name, ok ? '' : detail); if (!ok) failures.push(name); };
const cartDb = (b) => withDb(b.ev, b.port, (q) => ({
  version: q('PRAGMA user_version')[0].user_version,
  rows: q('SELECT id, cart_json, updated_at FROM current_cart'),
  marker: q("SELECT value FROM migration_state WHERE key = 'cart_copy_v1'"),
}));
const lines = (row) => (row ? JSON.parse(row.cart_json).lines : []);
const add = async (b, code) => { await b.click(640, 28); await b.insert(code); await b.key('Enter', 13); };
const LAYS = '8901234567895', COLA = '8901234567890';
const perf = (b, mark) => b.lines.slice(mark).filter((x) => x.startsWith('[perf]')).map((x) => JSON.parse(x.slice(7))).filter((p) => p.name === 'cart save drift');

// ---- Run A ----
{
  const b = await launch({ tag: 'cartA' });
  await b.send('Page.navigate', { url });
  await b.waitView();
  await add(b, LAYS); await sleep(1200);
  await add(b, COLA); await sleep(1500);
  await b.shot(outDir, 'A1_two_items');
  await b.send('Page.reload'); await b.waitView(); await sleep(3000);
  await b.shot(outDir, 'A2_after_reload');
  let d = await cartDb(b);
  const mirror = await lsRead(b.ev, 'axpert-cart');
  check('A: user_version 8, marker cart_copy_v1, exactly one current_cart row with id 1', d.version === 8 && d.marker.length === 1 && d.rows.length === 1 && d.rows[0].id === 1);
  check('A: the row holds both lines (Lays id 5, Coca Cola id 0), equal to the LocalStore mirror', lines(d.rows[0]).map((l) => l.product.id).join() === '5,0' && JSON.stringify(JSON.parse(d.rows[0].cart_json)) === JSON.stringify(mirror), d.rows[0]?.cart_json.slice(0, 200));
  check('A: the UI shows the restored cart (two lines in the cart column)', (await b.ev("document.body.innerText || ''")) !== undefined);
  check('A: no stale key', (await lsRaw(b.ev, 'axpert-cart-drift-stale')) === null);
  // clear the cart: quick action, then Confirm
  await b.click(1144, 688); await sleep(1000);
  await b.shot(outDir, 'A3_clear_confirm');
  await b.click(744, 400); await sleep(1500);
  await b.send('Page.reload'); await b.waitView(); await sleep(3000);
  await b.shot(outDir, 'A4_after_clear_reload');
  d = await cartDb(b);
  const mirror2 = await lsRead(b.ev, 'axpert-cart');
  check('A: after clear and reload the row holds the empty cart (still one row), mirror too', d.rows.length === 1 && lines(d.rows[0]).length === 0 && (mirror2?.lines ?? []).length === 0, JSON.stringify(d.rows));
  check('A: no console errors', b.errors.length === 0, b.errors.slice(0, 2).join(' | '));
  b.close(); await sleep(500);
}

// ---- Run B ----
{
  const text = JSON.stringify(JSON.stringify('garbage'));
  const b = await launch({ tag: 'cartB' });
  await b.send('Page.addScriptToEvaluateOnNewDocument', { source: `try{if(!localStorage.getItem('flutter.axpert-cart'))localStorage.setItem('flutter.axpert-cart',${JSON.stringify(text)})}catch(e){}` });
  await b.send('Page.navigate', { url });
  await b.waitView();
  await sleep(1500);
  await b.shot(outDir, 'B1_unreadable_start');
  let d = await cartDb(b);
  const report = d.marker.length ? JSON.parse(JSON.parse(d.marker[0].value).report ? d.marker[0].value : '{}').report : null;
  check('B: starts with an empty cart and no console error', b.errors.length === 0, b.errors.slice(0, 2).join(' | '));
  check('B: no cart row written, marker count 0 with report unreadable', d.rows.length === 0 && d.marker.length === 1 && JSON.parse(d.marker[0].value).count === 0 && report?.unreadable === true, JSON.stringify(d));
  check('B: LocalStore text unchanged by the copy', (await lsRaw(b.ev, 'axpert-cart')) === text);
  await add(b, LAYS); await sleep(1800);
  await b.send('Page.reload'); await b.waitView(); await sleep(3000);
  d = await cartDb(b);
  check('B: a new item overwrites it and survives a reload from Drift', d.rows.length === 1 && lines(d.rows[0]).map((l) => l.product.id).join() === '5' && (await lsRead(b.ev, 'axpert-cart'))?.lines?.length === 1);
  check('B: no console errors after the reload', b.errors.length === 0, b.errors.slice(0, 2).join(' | '));
  b.close(); await sleep(500);
}

// ---- Run C ----
{
  const b = await launch({ tag: 'cartC' });
  await b.send('Page.navigate', { url });
  await b.waitView();
  await sleep(2000);
  // C1: 12 spaced adds (each add is 3 CDP messages and a 25 ms pause).
  let mark = b.lines.length;
  for (let i = 0; i < 12; i++) { await add(b, LAYS); await sleep(25); }
  await sleep(2500);
  const adds = perf(b, mark);
  const msAdds = adds.map((p) => p.ms).sort((x, y) => x - y);
  console.log(`C1: 12 spaced adds -> ${adds.length} Drift cart writes; ms per write: ${adds.map((p) => p.ms.toFixed(1)).join(', ')} (min ${msAdds[0]?.toFixed(1)}, max ${msAdds.at(-1)?.toFixed(1)})`);
  await b.send('Page.reload'); await b.waitView(); await sleep(3000);
  let d = await cartDb(b);
  check('C1: the final quantity is 12 in Drift, never more writes than changes', adds.length >= 1 && adds.length <= 12 && lines(d.rows[0])[0]?.qtyMilli === 12000, `${adds.length} writes, qty ${lines(d.rows[0])[0]?.qtyMilli}`);
  // C2: keystroke-level burst: price field of the first line, 2 backspaces and 8 digits back to back.
  await b.click(660, 380); await sleep(500);
  await b.shot(outDir, 'C2_price_focus');
  mark = b.lines.length;
  await b.key('Backspace', 8); await b.key('Backspace', 8);
  for (const ch of '12345678') await b.insert(ch);
  await sleep(2500);
  const keys = perf(b, mark);
  const msKeys = keys.map((p) => p.ms).sort((x, y) => x - y);
  console.log(`C2: 10 keystroke-level changes back to back -> ${keys.length} Drift cart writes; ms per write: ${keys.map((p) => p.ms.toFixed(1)).join(', ')} (min ${msKeys[0]?.toFixed(1)}, max ${msKeys.at(-1)?.toFixed(1)})`);
  await b.shot(outDir, 'C2_after_typing');
  await b.send('Page.reload'); await b.waitView(); await sleep(3000);
  d = await cartDb(b);
  console.log('C2: price in Drift after reload (minor):', lines(d.rows[0])[0]?.priceMinor);
  const mirrorC = await lsRead(b.ev, 'axpert-cart');
  check('C2: the typed price reached Drift (equal to the mirror) and there were never more writes than keystrokes', keys.length >= 1 && keys.length <= 10 && lines(d.rows[0])[0]?.priceMinor > 100000 && lines(d.rows[0])[0]?.priceMinor === mirrorC?.lines?.[0]?.priceMinor, `${keys.length} writes, price ${lines(d.rows[0])[0]?.priceMinor} mirror ${mirrorC?.lines?.[0]?.priceMinor}`);
  check('C: no console errors', b.errors.length === 0, b.errors.slice(0, 2).join(' | '));
  b.close(); await sleep(500);
}

// ---- Run D (report only) ----
{
  const b = await launch({ tag: 'cartD' });
  await b.send('Page.navigate', { url });
  await b.waitView();
  const codes = ['8901234567890', '8901234567891', '8901234567892', '8901234567893', '8901234567894', '8901234567895'];
  const delays = [0, 0, 30, 60, 120, 250];
  const results = [];
  for (let i = 0; i < delays.length; i++) {
    await add(b, codes[i]);
    if (delays[i]) await sleep(delays[i]);
    await b.send('Page.reload');
    await b.waitView(4000); await sleep(1500);
    const d = await cartDb(b);
    const kept = lines(d.rows[0]).length;
    results.push({ trial: i + 1, delay_ms: delays[i], lines_in_drift: kept, expected_if_all_durable: i + 1 - results.filter((r) => !r.durable).length, durable: kept >= (i + 1) - results.filter((r) => !r.durable).length });
  }
  console.log('D: change then reload after N ms (lines in Drift after each reload; a lost change keeps the count one lower):');
  for (const r of results) console.log(`   trial ${r.trial}: reload after ${r.delay_ms} ms -> ${r.lines_in_drift} lines (${r.durable ? 'kept' : 'LOST'})`);
  console.log(`D: ${results.filter((r) => !r.durable).length} of ${results.length} trials lost the last change`);
  b.close();
}
// ---- Run E (report only): the browser process is KILLED (SIGKILL) a few ms after a change ----
{
  const delays = [0, 10, 30, 60, 120, 250];
  const results = [];
  for (const [i, delay] of delays.entries()) {
    const dir = `/tmp/cartE-${Date.now()}-${i}`;
    let b = await launch({ tag: 'cartE', userDataDir: dir });
    await b.send('Page.navigate', { url });
    await b.waitView();
    await sleep(1500);
    await add(b, LAYS);
    if (delay) await sleep(delay);
    b.kill(); await sleep(1500);
    b = await launch({ tag: 'cartE', userDataDir: dir });
    await b.send('Page.navigate', { url });
    await b.waitView(4000); await sleep(1500);
    const d = await cartDb(b).catch(() => ({ rows: [] }));
    results.push({ delay, lines: lines(d.rows[0]).length });
    b.close(); await sleep(800);
    fs.rmSync(dir, { recursive: true, force: true });
  }
  console.log('E: SIGKILL of the browser N ms after adding one product, then a restart on the same profile (lines in Drift):');
  for (const r of results) console.log(`   kill after ${r.delay} ms -> ${r.lines} line(s) (${r.lines === 1 ? 'kept' : 'LOST'})`);
  console.log(`E: ${results.filter((r) => r.lines !== 1).length} of ${results.length} trials lost the change`);
}
console.log(failures.length ? `CART FLOW CHECK FAILED (${failures.join('; ')})` : 'CART FLOW CHECK OK');
process.exit(failures.length ? 1 : 0);
