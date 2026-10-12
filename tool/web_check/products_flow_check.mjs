// Release-build check that products really persist in Drift (D4):
//   python3 tool/web_check/serve.py build/web 8300 &
//   node --experimental-websocket tool/web_check/products_flow_check.mjs http://127.0.0.1:8300/ <outDir>
// Run A (fresh profile, seed products): through the UI mark Pepsi as favourite, then sell
// Coca Cola x1 and Sprite x2 in a cash sale. RELOAD and read the Drift rows (sqlite3 CLI on a temp
// copy): stock 44/49, Pepsi favourite, ONLY those three rows have updated_at after created_at
// (changed rows only), the marker exists, LocalStore `axpert-products` equals the Drift rows,
// no stale key, no console errors.
// Run B (fresh profile): a 21-product list (one new product, id 20, fractional gst 5.5) is put
// into localStorage BEFORE the first load (the app has no add-product screen). Check the copy
// (21 rows, new UUID v4, position 20, gst_bp 550, LocalStore text unchanged byte for byte), then
// toggle a favourite through the UI, RELOAD and check Drift and LocalStore again.
// Exit 1 on any mismatch.
import fs from 'node:fs';
import { launch, withDb, lsRead, lsRaw, sleep, uuidRe } from './products_common.mjs';

const [url, outDir = '/tmp/products_flow'] = process.argv.slice(2);
fs.mkdirSync(outDir, { recursive: true });
const failures = [];
const check = (name, ok, detail = '') => { console.log(ok ? 'ok  ' : 'FAIL', name, ok ? '' : detail); if (!ok) failures.push(name); };
const productRows = (q) => q('SELECT id, legacy_id, position, name, stock, gst_bp, favourite, created_at, updated_at, deleted_at FROM products ORDER BY position');
const sameAsStore = (rows, store) => rows.length === store.length && rows.every((r, i) => store[i].id === r.legacy_id && store[i].stock === r.stock && store[i].favourite === (r.favourite === 1) && Math.round(store[i].gst * 100) === r.gst_bp);

// ---- Run A ----
{
  const b = await launch({ tag: 'prodflowA' });
  await b.send('Page.navigate', { url });
  await b.waitView();
  await b.click(402, 285); await sleep(1500);                 // Pepsi: favourite
  await b.click(236, 411); await sleep(500);                  // + Coca Cola
  await b.click(225, 538); await sleep(500);                  // + Sprite (the cart column opened, cards moved)
  await b.click(225, 538); await sleep(500);                  // + Sprite
  await b.shot(outDir, 'A1_cart');
  await b.key('F2', 113); await sleep(800);
  await b.key('Enter', 13); await sleep(3500);                // complete cash sale
  await b.shot(outDir, 'A2_after_checkout');
  const before = await lsRead(b.ev, 'axpert-products');
  console.log('A before reload: LocalStore stock id0/id2', before?.[0]?.stock, before?.[2]?.stock, 'favourite id1', before?.[1]?.favourite);
  await b.send('Page.reload'); await b.waitView(); await sleep(3000);
  await b.shot(outDir, 'A3_after_reload');
  const rows = await withDb(b.ev, b.port, (q) => ({ rows: productRows(q), marker: q("SELECT value FROM migration_state WHERE key = 'products_copy_v1'"), version: q('PRAGMA user_version')[0].user_version }));
  const store = await lsRead(b.ev, 'axpert-products');
  const stale = await lsRaw(b.ev, 'axpert-products-drift-stale');
  const changed = rows.rows.filter((r) => r.updated_at > r.created_at).map((r) => r.legacy_id);
  check('A: 20 active rows, user_version 8, marker present', rows.rows.length === 20 && rows.rows.every((r, i) => r.position === i && !r.deleted_at && uuidRe.test(r.id)) && rows.version === 8 && rows.marker.length === 1);
  check('A: stock id0=44 and id2=49 in Drift', rows.rows[0].stock === 44 && rows.rows[2].stock === 49, JSON.stringify(rows.rows.slice(0, 3)));
  check('A: Pepsi (id1) favourite in Drift', rows.rows[1].favourite === 1);
  check('A: only the 3 changed rows have updated_at after created_at', changed.join() === '0,1,2', changed.join());
  check('A: LocalStore equals the Drift rows after reload', sameAsStore(rows.rows, store));
  check('A: no stale key', stale === null);
  check('A: no console errors', b.errors.length === 0, b.errors.slice(0, 2).join(' | '));
  b.close(); await sleep(500);
}

// ---- Run B ----
{
  const list = Array.from({ length: 21 }, (_, i) => ({ id: i, name: i === 20 ? 'Injected 21st' : `Item ${i}`, code: `INJ${String(i).padStart(3, '0')}`, barcode: String(8900000001000 + i), priceMinor: 1000 + i, category: 'Snacks', sub: 'Chips', stock: 10 + i, gst: i === 20 ? 5.5 : 18, image: -1, favourite: false }));
  const text = JSON.stringify(JSON.stringify(list));
  const b = await launch({ tag: 'prodflowB' });
  await b.send('Page.addScriptToEvaluateOnNewDocument', { source: `try{if(!localStorage.getItem('flutter.axpert-products'))localStorage.setItem('flutter.axpert-products',${JSON.stringify(text)})}catch(e){}` });
  await b.send('Page.navigate', { url });
  await b.waitView();
  await sleep(2000);
  await b.shot(outDir, 'B1_first_load');
  let rows = await withDb(b.ev, b.port, (q) => ({ rows: productRows(q), marker: q("SELECT value FROM migration_state WHERE key = 'products_copy_v1'") }));
  check('B: 21 rows copied, new product at position 20 with its own UUID v4 and gst_bp 550', rows.rows.length === 21 && rows.rows[20].legacy_id === 20 && rows.rows[20].gst_bp === 550 && rows.rows.every((r) => uuidRe.test(r.id)) && new Set(rows.rows.map((r) => r.id)).size === 21 && JSON.parse(rows.marker[0].value).count === 21);
  check('B: LocalStore text unchanged byte for byte by the copy', (await lsRaw(b.ev, 'axpert-products')) === text);
  // The first product card is the first injected product: star at the first card.
  await b.click(236, 285); await sleep(1500);
  await b.shot(outDir, 'B2_favourite');
  await b.send('Page.reload'); await b.waitView(); await sleep(3000);
  rows = await withDb(b.ev, b.port, (q) => ({ rows: productRows(q) }));
  const store = await lsRead(b.ev, 'axpert-products');
  const changed = rows.rows.filter((r) => r.updated_at > r.created_at).map((r) => r.legacy_id);
  check('B: after the UI favourite toggle and a reload exactly one row changed', changed.length === 1 && rows.rows.filter((r) => r.favourite === 1).length === 1, changed.join());
  check('B: LocalStore equals the Drift rows, 21 products, gst 5.5 kept as 5.5', rows.rows.length === 21 && sameAsStore(rows.rows, store) && store[20].gst === 5.5);
  check('B: no stale key, no console errors', (await lsRaw(b.ev, 'axpert-products-drift-stale')) === null && b.errors.length === 0, b.errors.slice(0, 2).join(' | '));
  b.close();
}
console.log(failures.length ? `PRODUCTS FLOW CHECK FAILED (${failures.join('; ')})` : 'PRODUCTS FLOW CHECK OK');
process.exit(failures.length ? 1 : 0);
