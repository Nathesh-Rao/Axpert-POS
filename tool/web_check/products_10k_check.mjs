// Release-build timing of 10,000 products in Drift (D4). Needs a build with the timeline on:
//   flutter build web --dart-define=STARTUP_TIMELINE=true -o build/web_timeline
//   python3 tool/web_check/serve.py build/web_timeline 8301 &
//   node --experimental-websocket tool/web_check/products_10k_check.mjs http://127.0.0.1:8301/ <outDir>
// Fresh profile; the same deterministic 10k list as the debug-only LargeDataset (a JS port of its
// formula, because LargeDataset is compiled out of release builds) is written to localStorage
// BEFORE the first load, so the first start does the copy. Reports, from the `[startup]` and
// `[perf]` console lines: copy time, read time, `load products`, the first run's loadData and
// first frame, then a RELOAD (marker present: no copy), then two checkouts of two products
// each (D5: receipt time, one Drift transaction, whole-list mirrors; the first write after the
// reload and the steady state). Checks the Drift rows against the injected list and
// against LocalStore. Exit 1 on a mismatch or a console error.
import fs from 'node:fs';
import { launch, withDb, lsRead, sleep, uuidRe } from './products_common.mjs';

const [url, outDir = '/tmp/products_10k'] = process.argv.slice(2);
fs.mkdirSync(outDir, { recursive: true });
const cats = [['Beverages', ['Soft Drinks', 'Juices', 'Water']], ['Snacks', ['Chips', 'Biscuits', 'Confectionery', 'Noodles']], ['Personal Care', ['Oral Care', 'Bath & Body', 'Hair Care']]];
const pad = (i) => String(i).padStart(5, '0');
const list = Array.from({ length: 10000 }, (_, i) => {
  const cat = cats[i % 3]; const sub = cat[1][Math.floor(i / 3) % cat[1].length];
  return { id: i, name: `Item ${pad(i)} ${cat[0].split(' ')[0]}`, code: `LD${pad(i)}`, barcode: String(8900000000000 + i), priceMinor: (10 + (i * 7) % 490) * 100, category: cat[0], sub, stock: 5 + (i * 13) % 200, gst: [18, 12, 5][i % 3], image: i < 12 ? i : -1, favourite: i % 17 === 0 };
});
const text = JSON.stringify(JSON.stringify(list));
const failures = [];
const check = (name, ok, detail = '') => { console.log(ok ? 'ok  ' : 'FAIL', name, ok ? '' : detail); if (!ok) failures.push(name); };
const ms = (us) => (us / 1000).toFixed(0);
const phases = (lines, from) => {
  const l = lines.slice(from).find((x) => x.startsWith('[startup]'));
  return l ? JSON.parse(l.slice('[startup] '.length)).phases : null;
};
const dur = (ph, name) => ph?.filter((p) => p.name === name).map((p) => ms(p.dur)).join('/') ?? 'n/a';
const at = (ph, name) => ph?.find((p) => p.name === name) ? ms(ph.find((p) => p.name === name).at) : 'n/a';

const b = await launch({ tag: 'prod10k', width: 1280, height: 720 });
await b.send('Page.addScriptToEvaluateOnNewDocument', { source: `try{if(!localStorage.getItem('flutter.axpert-products'))localStorage.setItem('flutter.axpert-products',${JSON.stringify(text)})}catch(e){}` });
const t0 = Date.now();
await b.send('Page.navigate', { url });
let first = null;
for (let i = 0; i < 1800 && !first; i++) { first = b.lines.find((x) => x.startsWith('[startup]')); await sleep(100); }
const firstMs = Date.now() - t0;
await sleep(2500);
const run1 = phases(b.lines, 0);
console.log(`FIRST START (copy): wall to [startup] line ${firstMs} ms`);
console.log(`  products drift copy ${dur(run1, 'products drift copy')} ms | products drift read ${dur(run1, 'products drift read')} ms | load products ${dur(run1, 'load products')} ms | loadData ${dur(run1, 'loadData (all)')} ms | runApp at ${at(run1, 'runApp called')} ms | first frame built at ${at(run1, 'first frame built')} ms | rasterized at ${at(run1, 'first frame rasterized')} ms`);
await b.shot(outDir, '1_first_start');
let rows = await withDb(b.ev, b.port, (q) => ({
  count: q('SELECT COUNT(*) AS n FROM products')[0].n,
  sample: q('SELECT id, legacy_id, position, stock, gst_bp, favourite FROM products WHERE legacy_id IN (0, 5000, 9999) ORDER BY legacy_id'),
  ids: q('SELECT COUNT(DISTINCT id) AS n FROM products')[0].n,
  marker: q("SELECT value FROM migration_state WHERE key = 'products_copy_v1'"),
}));
check('10,000 rows copied, 10,000 distinct UUIDs, marker count 10000', rows.count === 10000 && rows.ids === 10000 && JSON.parse(rows.marker[0].value).count === 10000, JSON.stringify(rows).slice(0, 200));
check('sample rows: positions, stock and gst_bp match the list', rows.sample.every((r) => r.position === r.legacy_id && r.stock === list[r.legacy_id].stock && r.gst_bp === list[r.legacy_id].gst * 100 && uuidRe.test(r.id)));

// reload: marker present, no copy
const mark = b.lines.length;
await b.send('Page.reload');
for (let i = 0; i < 1800 && !b.lines.slice(mark).some((x) => x.startsWith('[startup]')); i++) await sleep(100);
await sleep(2500);
const run2 = phases(b.lines, mark);
console.log('RELOAD (marker present):');
console.log(`  products drift copy(check) ${dur(run2, 'products drift copy')} ms | products drift read ${dur(run2, 'products drift read')} ms | load products ${dur(run2, 'load products')} ms | loadData ${dur(run2, 'loadData (all)')} ms | first frame built at ${at(run2, 'first frame built')} ms`);

// two checkouts of two products each via the search box (barcode + Enter), then F2 / Enter.
// The first one is the first write after the reload; the second shows the steady state.
const checkout = async (n, a, c) => {
  const mark = b.lines.length;
  await b.click(640, 28); await b.insert(String(8900000000000 + a)); await b.key('Enter', 13); await sleep(1200);
  await b.click(640, 28); await b.insert(String(8900000000000 + c)); await b.key('Enter', 13); await sleep(1200);
  await b.shot(outDir, `${n}_cart`);
  await b.key('F2', 113); await sleep(800);
  await b.key('Enter', 13); await sleep(6000);
  await b.shot(outDir, `${n}_after_checkout`);
  const perf = b.lines.slice(mark).filter((x) => x.startsWith('[perf]')).map((x) => JSON.parse(x.slice(7)));
  console.log(`CHECKOUT ${n} (2 products, 10,000-product list):`, perf.map((p) => `${p.name}: ${p.ms.toFixed(1)} ms`).join(' | ') || 'NO [perf] LINES');
  const commit = perf.find((p) => p.name.startsWith('checkout commit ('));
  const receipt = perf.find((p) => p.name === 'checkout receipt');
  console.log(`  -> receipt (memory update to receipt open) ${receipt?.ms.toFixed(1) ?? 'n/a'} ms | transaction ${commit?.ms.toFixed(1) ?? 'n/a'} ms (${commit?.name}) | three mirrors ${perf.find((p) => p.name === 'checkout mirror')?.ms.toFixed(1) ?? 'n/a'} ms`);
  check(`checkout ${n}: one transaction: 1 sale + 2 lines + 2 stock rows (5 planned rows, the payment row is extra), mirrors written, receipt timed`, !!commit && /checkout commit \(5 rows\)/.test(commit.name) && perf.some((p) => p.name === 'checkout mirror') && !!receipt, JSON.stringify(perf));
};
await checkout(1, 10, 11);
await checkout(2, 12, 13);

await b.send('Page.reload'); await b.waitView(); await sleep(3000);
rows = await withDb(b.ev, b.port, (q) => ({
  changed: q('SELECT legacy_id, stock FROM products WHERE updated_at > created_at ORDER BY legacy_id'),
  count: q('SELECT COUNT(*) AS n FROM products')[0].n,
  all: q('SELECT legacy_id, stock, favourite FROM products ORDER BY position'),
}));
const store = await lsRead(b.ev, 'axpert-products');
check('only the 4 sold rows changed in Drift, stock minus 1', rows.changed.length === 4 && rows.changed.every((r) => r.stock === list[r.legacy_id].stock - 1) && rows.changed.map((r) => r.legacy_id).join() === '10,11,12,13', JSON.stringify(rows.changed));
check('LocalStore (10,000) equals the Drift rows', store.length === 10000 && rows.all.every((r, i) => store[i].id === r.legacy_id && store[i].stock === r.stock && store[i].favourite === (r.favourite === 1)));
check('no console errors', b.errors.length === 0, b.errors.slice(0, 2).join(' | '));
b.close();
console.log(failures.length ? `PRODUCTS 10K CHECK FAILED (${failures.join('; ')})` : 'PRODUCTS 10K CHECK OK');
process.exit(failures.length ? 1 : 0);
