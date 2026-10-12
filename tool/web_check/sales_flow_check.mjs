// Release-build check that a sale and a refund really persist in Drift as one unit (D5, DEC-129):
//   python3 tool/web_check/serve.py build/web 8300 &
//   node --experimental-websocket tool/web_check/sales_flow_check.mjs http://127.0.0.1:8300/ <outDir>
// Fresh profile, 1280x720. Through the UI: pick Priya Nair (400 points), add Lays and Coca Cola,
// redeem 10 points, complete a CASH sale (F2, Enter). RELOAD, rebuild the SQLite file from
// IndexedDB (sqlite3 CLI, temp copy deleted) and check: one sale (UUID id = the saleId in the
// LocalStore JSON, has_sale_id 1, customer link set, totals), two lines with the product
// snapshot, one payment (cash, amount = total), stock minus 1 on both products, Priya 390
// points, the marker, LocalStore sales/products/customers equal to Drift, no stale keys.
// Then, through the Returns page, refund 1 of Lays, RELOAD and check: returned_qty_milli 1000
// on that line only, returned_order [id], sales.updated_at after created_at, Lays stock back
// +1 in the same transaction (same updated_at), LocalStore `returned` map, no console errors.
// Exit 1 on any mismatch.
import fs from 'node:fs';
import { launch, withDb, lsRead, lsRaw, sleep, uuidRe } from './products_common.mjs';

const [url, outDir = '/tmp/sales_flow'] = process.argv.slice(2);
fs.mkdirSync(outDir, { recursive: true });
const failures = [];
const check = (name, ok, detail = '') => { console.log(ok ? 'ok  ' : 'FAIL', name, ok ? '' : detail); if (!ok) failures.push(name); };
const read = (b) => withDb(b.ev, b.port, (q) => ({
  version: q('PRAGMA user_version')[0].user_version,
  sales: q('SELECT id, has_sale_id, number, position, customer_name, customer_legacy_id, customer_id, mode, total_minor, tendered_minor, returned_order, created_at, updated_at, deleted_at FROM sales ORDER BY position'),
  lines: q('SELECT sale_id, line_no, product_id, product_legacy_id, product_name, qty_milli, returned_qty_milli FROM sale_lines ORDER BY sale_id, line_no'),
  payments: q('SELECT id, sale_id, method, amount_minor, status FROM payments'),
  products: q('SELECT legacy_id, stock, created_at, updated_at FROM products ORDER BY position'),
  customers: q('SELECT legacy_id, points FROM customers ORDER BY position'),
  marker: q("SELECT value FROM migration_state WHERE key = 'sales_copy_v1'"),
}));

const b = await launch({ tag: 'salesflow' });
await b.send('Page.navigate', { url });
await b.waitView();
await b.click(190, 103); await sleep(800); await b.click(166, 256); await sleep(1000);       // picker -> Priya Nair
await b.click(640, 28); await b.insert('8901234567895'); await b.key('Enter', 13); await sleep(1200); // Lays (id 5)
await b.click(640, 28); await b.insert('8901234567890'); await b.key('Enter', 13); await sleep(1200); // Coca Cola (id 0)
await b.click(1190, 413); await b.insert('10'); await sleep(600);                             // redeem 10 points
await b.shot(outDir, '1_before_checkout');
await b.key('F2', 113); await sleep(800);
await b.key('Enter', 13); await sleep(3500);                                                  // complete cash sale
await b.shot(outDir, '2_after_checkout');
const stockBefore = (await lsRead(b.ev, 'axpert-products'));
console.log('before reload: LocalStore sales', (await lsRead(b.ev, 'axpert-sales'))?.length, '| stock id0/id5', stockBefore?.[0]?.stock, stockBefore?.[5]?.stock);

await b.send('Page.reload'); await b.waitView(); await sleep(3000);
await b.shot(outDir, '3_after_reload');
let d = await read(b);
const mirrorSales = await lsRead(b.ev, 'axpert-sales');
const mirrorProducts = await lsRead(b.ev, 'axpert-products');
const mirrorCustomers = await lsRead(b.ev, 'axpert-customers');
const sale = d.sales[0];
check('A: user_version 8, marker sales_copy_v1, exactly one sale (position 0)', d.version === 8 && d.marker.length === 1 && d.sales.length === 1 && sale.position === 0 && !sale.deleted_at);
check('A: sale id is a UUID v4 equal to the saleId in the LocalStore JSON, has_sale_id 1', !!sale && uuidRe.test(sale.id) && sale.has_sale_id === 1 && mirrorSales?.[0]?.saleId === sale.id && mirrorSales[0].number === sale.number, JSON.stringify(sale));
check('A: customer is Priya (legacy id 3), link to the customer row set, mode Cash', sale?.customer_name === 'Priya Nair' && sale.customer_legacy_id === '3' && !!sale.customer_id && sale.mode === 'Cash', JSON.stringify(sale));
check('A: two lines (Lays id 5, Coca Cola id 0) with product links and nothing returned', d.lines.length === 2 && d.lines.map((l) => l.product_legacy_id).sort().join() === '0,5' && d.lines.every((l) => !!l.product_id && l.returned_qty_milli === 0 && l.sale_id === sale.id), JSON.stringify(d.lines));
check('A: one cash payment of the amount due, succeeded', d.payments.length === 1 && d.payments[0].method === 'cash' && d.payments[0].sale_id === sale.id && d.payments[0].amount_minor === sale.total_minor && d.payments[0].status === 'succeeded' && uuidRe.test(d.payments[0].id), JSON.stringify(d.payments));
const p0 = d.products.find((p) => p.legacy_id === 0), p5 = d.products.find((p) => p.legacy_id === 5);
check('A: stock of both products minus 1 in Drift', p0.stock === 44 && p5.stock === 59, `${p0.stock}/${p5.stock}`);
check('A: only the two sold product rows changed', d.products.filter((p) => p.updated_at > p.created_at).map((p) => p.legacy_id).sort().join() === '0,5');
check('A: Priya has 390 points in Drift', d.customers.find((c) => c.legacy_id === '3')?.points === 390, JSON.stringify(d.customers));
check('A: LocalStore mirrors equal Drift (sales count, stock, points)', mirrorSales.length === 1 && mirrorProducts[0].stock === 44 && mirrorProducts[5].stock === 59 && mirrorCustomers.find((c) => c.id === '3').points === 390);
check('A: no stale keys', (await lsRaw(b.ev, 'axpert-sales-drift-stale')) === null && (await lsRaw(b.ev, 'axpert-products-drift-stale')) === null && (await lsRaw(b.ev, 'axpert-customers-drift-stale')) === null);
check('A: no console errors', b.errors.length === 0, b.errors.slice(0, 2).join(' | '));

// ---- two refunds through the Returns page: Coca Cola first, then Lays (refund order != line order) ----
const refund = async (name, qtyX, qtyY, shotName) => {
  await b.click(32, 395); await sleep(1500);                                                   // Returns
  await b.click(374, 240); await b.insert(sale.number); await sleep(1200);
  await b.click(qtyX, qtyY); await b.key('Backspace', 8); await b.insert('1'); await sleep(500);
  await b.shot(outDir, `${shotName}_typed`);
  await b.click(374, 500); await sleep(1000);                                                  // Refund & restock
  await b.shot(outDir, `${shotName}_confirm`);
  await b.click(744, 400); await sleep(2500);                                              // Confirm
  await b.shot(outDir, `${shotName}_done`);
  await b.send('Page.reload'); await b.waitView(); await sleep(3000);
  console.log(`refund of ${name} done and reloaded`);
};

await refund('Coca Cola x1', 609, 422, '4_refund1');
d = await read(b);
let s1 = d.sales[0];
let ms = await lsRead(b.ev, 'axpert-sales');
let mp = await lsRead(b.ev, 'axpert-products');
const lineOf = (id) => d.lines.find((l) => l.product_legacy_id === id);
check('B1: Coca Cola line returned 1000 milli, Lays line untouched', lineOf(0)?.returned_qty_milli === 1000 && lineOf(5)?.returned_qty_milli === 0, JSON.stringify(d.lines));
check('B1: returned_order [0], updated_at after created_at, still ONE sale row, no new payment', s1.returned_order === '[0]' && s1.updated_at > s1.created_at && d.sales.length === 1 && d.payments.length === 1, JSON.stringify(s1));
const c0 = d.products.find((p) => p.legacy_id === 0), l5 = d.products.find((p) => p.legacy_id === 5);
check('B1: Coca Cola stock back to 45 in the same transaction (updated_at equals the sale row), Lays still 59', c0.stock === 45 && l5.stock === 59 && c0.updated_at === s1.updated_at, `${c0.stock}/${l5.stock} ${c0.updated_at} vs ${s1.updated_at}`);
check('B1: LocalStore returned map and stock agree', JSON.stringify(ms[0].returned) === '{"0":1000}' && mp[0].stock === 45 && mp[5].stock === 59, JSON.stringify(ms[0].returned));

await refund('Lays x1', 609, 349, '5_refund2');
d = await read(b);
s1 = d.sales[0];
ms = await lsRead(b.ev, 'axpert-sales');
mp = await lsRead(b.ev, 'axpert-products');
check('B2: both lines returned 1000 milli, returned_order [0,5] (refund order, not line order)', lineOf(0)?.returned_qty_milli === 1000 && lineOf(5)?.returned_qty_milli === 1000 && s1.returned_order === '[0,5]', JSON.stringify(d.lines) + s1.returned_order);
check('B2: LocalStore `returned` map is byte-identical in order {"0":1000,"5":1000}', JSON.stringify(ms[0].returned) === '{"0":1000,"5":1000}', JSON.stringify(ms[0].returned));
check('B2: stock 45 and 60, one sale row, one payment, no stale keys', d.products.find((p) => p.legacy_id === 0).stock === 45 && d.products.find((p) => p.legacy_id === 5).stock === 60 && mp[5].stock === 60 && d.sales.length === 1 && d.payments.length === 1 && (await lsRaw(b.ev, 'axpert-sales-drift-stale')) === null && (await lsRaw(b.ev, 'axpert-products-drift-stale')) === null);
check('no console errors in the whole run', b.errors.length === 0, b.errors.slice(0, 2).join(' | '));
b.close();
console.log(failures.length ? `SALES FLOW CHECK FAILED (${failures.join('; ')})` : 'SALES FLOW CHECK OK');
process.exit(failures.length ? 1 : 0);
