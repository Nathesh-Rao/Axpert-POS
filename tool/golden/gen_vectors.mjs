// Generates test/fixtures/pricing_golden.json (and the .g.dart copy the tests
// load on every platform) from React's REAL calculate()/cartReducer.
//
// Usage (from pos_application/):
//   npx --yes esbuild ../reference_react/src/data.ts --format=esm --outfile=$TMP/data.mjs
//   node tool/golden/gen_vectors.mjs $TMP/data.mjs
// Nothing is written into reference_react/. Nothing is installed.
// NOTE: needs ../reference_react/ (read-only reference outside git). It stops working when that folder is deleted after Phase A; the generated fixtures stay committed.
import { writeFileSync } from 'node:fs'
import { pathToFileURL } from 'node:url'
import { resolve } from 'node:path'

const dataPath = process.argv[2]
if (!dataPath) throw new Error('pass the transpiled data.mjs path')
const { calculate, cartReducer, emptyCart } = await import(
  pathToFileURL(resolve(dataPath)).href
)

// ---- seeded PRNG (mulberry32) ----
let seed = 20261008
const rnd = () => {
  seed |= 0
  seed = (seed + 0x6d2b79f5) | 0
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed)
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296
}
const ri = (lo, hi) => lo + Math.floor(rnd() * (hi - lo + 1))
const pick = (a) => a[ri(0, a.length - 1)]
const dec = (n, scale) => {
  // integer n at `scale` decimals -> canonical decimal string
  const neg = n < 0
  const s = String(Math.abs(n)).padStart(scale + 1, '0')
  const out = scale ? `${s.slice(0, -scale)}.${s.slice(-scale)}` : s
  return (neg ? '-' : '') + out
}

const vectors = []
const product = (gst, id) => ({
  id, name: `P${id}`, code: '', barcode: '', price: 0, category: '', sub: '',
  stock: 1e9, gst, image: 0, favourite: false,
})

// A vector is described by decimal strings; JS receives Number(string).
function vector(id, spec) {
  const { lines, discountType = 'percent', billDiscount = '0', points = '0',
    available = '0' } = spec
  let cart = { ...emptyCart, discountType, billDiscount: Number(billDiscount),
    points: Number(points) }
  cart = {
    ...cart,
    lines: lines.map((l, i) => ({
      product: product(Number(l.gst), i), qty: Number(l.qty),
      price: Number(l.price), discount: Number(l.discount ?? '0'),
    })),
  }
  const t = calculate(cart, Number(available))
  const negZero = Object.keys(t).filter((k) => Object.is(t[k], -0))
  vectors.push({
    id, name: spec.name ?? id, lines: lines.map((l) => ({
      qty: l.qty, price: l.price, discount: l.discount ?? '0', gst: String(l.gst),
    })),
    discountType, billDiscount, points, available,
    expected: {
      items: t.items, qtyMilli: Math.round(t.qty * 1000),
      value: t.value.toFixed(2), subtotal: t.subtotal.toFixed(2),
      discount: t.discount.toFixed(2), tax: t.tax.toFixed(2),
      points: t.points.toFixed(2), total: t.total.toFixed(2),
    },
    negZero,
  })
}

// Same, but the lines come out of the real cartReducer (clamps included).
function reducerVector(id, name, stock, steps, extra = {}) {
  let cart = { ...emptyCart }
  const p = (gst, idx) => ({ ...product(gst, idx), stock })
  for (const s of steps) {
    cart = cartReducer(cart, s.type === 'addItem'
      ? { type: 'addItem', product: p(s.gst, s.id) } : s)
  }
  const lines = cart.lines.map((l) => ({
    qty: String(l.qty), price: String(l.price),
    discount: String(l.discount), gst: String(l.product.gst),
  }))
  vector(id, { name, lines, ...extra })
}

// ---- hand-written edge cases ----
const L = (qty, price, discount, gst) => ({ qty, price, discount, gst })
let n = 0
const hid = () => `h${String(++n).padStart(3, '0')}`
vector(hid(), { name: 'empty cart', lines: [] })
vector(hid(), { name: 'empty cart with discount and points', lines: [],
  billDiscount: '10', points: '50', available: '100' })
vector(hid(), { name: 'single line no tax', lines: [L('1', '40.00', '0', 0)] })
for (const g of [0, 5, 12, 18]) {
  vector(hid(), { name: `slab ${g}`, lines: [L('3', '40.00', '0', g)] })
  vector(hid(), { name: `slab ${g} odd price`, lines: [L('7', '19.99', '0', g)] })
  vector(hid(), { name: `slab ${g} with line+bill pct`,
    lines: [L('2.5', '33.33', '12.5', g), L('1', '99.00', '0', g)], billDiscount: '7.5' })
}
vector(hid(), { name: '100% line discount', lines: [L('2', '50.00', '100', 18)] })
vector(hid(), { name: '100% line discount plus another line',
  lines: [L('2', '50.00', '100', 18), L('1', '10.00', '0', 12)] })
vector(hid(), { name: '100% bill discount', lines: [L('2', '50.00', '0', 18)],
  billDiscount: '100' })
vector(hid(), { name: 'bill discount over 100%', lines: [L('2', '50.00', '0', 18)],
  billDiscount: '250' })
vector(hid(), { name: 'flat above subtotal', lines: [L('2', '50.00', '10', 12)],
  discountType: 'flat', billDiscount: '500' })
vector(hid(), { name: 'flat below subtotal', lines: [L('2', '50.00', '0', 12), L('1', '20.00', '0', 5)],
  discountType: 'flat', billDiscount: '33.33' })
vector(hid(), { name: 'flat equals subtotal', lines: [L('2', '50.00', '0', 18)],
  discountType: 'flat', billDiscount: '100' })
vector(hid(), { name: 'points above payable', lines: [L('1', '40.00', '0', 18)],
  points: '500', available: '1000' })
vector(hid(), { name: 'points above available', lines: [L('10', '40.00', '0', 18)],
  points: '300', available: '120' })
vector(hid(), { name: 'points equal payable-ish', lines: [L('1', '40.00', '0', 18)],
  points: '47', available: '47' })
vector(hid(), { name: 'points with bill discount', lines: [L('3', '85.00', '5', 12)],
  billDiscount: '10', points: '100', available: '250' })
vector(hid(), { name: 'fractional qty', lines: [L('0.333', '100.00', '0', 18)] })
vector(hid(), { name: 'fractional qty 3 lines',
  lines: [L('0.125', '40.00', '0', 18), L('1.375', '110.00', '3.5', 12), L('2.001', '9.99', '0', 5)] })
vector(hid(), { name: 'tiny qty', lines: [L('0.001', '0.01', '0', 18)] })
vector(hid(), { name: 'zero price', lines: [L('5', '0.00', '0', 18)] })
vector(hid(), { name: 'zero price mixed', lines: [L('5', '0.00', '0', 18), L('1', '12.34', '0', 12)],
  billDiscount: '10' })
vector(hid(), { name: 'many lines same slab',
  lines: Array.from({ length: 8 }, (_, i) => L('1', String(10 + i) + '.05', '0', 18)),
  billDiscount: '3' })
vector(hid(), { name: 'half paise tax candidates',
  lines: [L('1', '0.10', '0', 5), L('1', '0.30', '0', 5), L('1', '0.50', '0', 5)] })
vector(hid(), { name: 'large amounts', lines: [L('999.999', '99999.99', '12.34', 18)], billDiscount: '5' })
vector(hid(), { name: 'large lakh amount', lines: [L('1000', '12345.67', '0', 12)],
  discountType: 'flat', billDiscount: '1234567.89' })
vector(hid(), { name: 'line discount tiny', lines: [L('3', '33.33', '0.01', 18)] })
vector(hid(), { name: 'bill discount tiny', lines: [L('3', '33.33', '0', 18)], billDiscount: '0.01' })
vector(hid(), { name: 'flat 0.01', lines: [L('3', '33.33', '0', 18)], discountType: 'flat', billDiscount: '0.01' })

reducerVector(hid(), 'reducer: add twice, setQty', 100, [
  { type: 'addItem', gst: 18, id: 0 }, { type: 'addItem', gst: 18, id: 0 },
  { type: 'setPrice', id: 0, value: 12.5 }, { type: 'setQty', id: 0, value: 3.25 }])
reducerVector(hid(), 'reducer: qty clamped to stock', 5, [
  { type: 'addItem', gst: 12, id: 1 }, { type: 'setQty', id: 1, value: 50 },
  { type: 'setPrice', id: 1, value: 40 }])
reducerVector(hid(), 'reducer: discount clamped to 100', 50, [
  { type: 'addItem', gst: 5, id: 2 }, { type: 'setPrice', id: 2, value: 80 },
  { type: 'setLineDiscount', id: 2, value: 250 }])
reducerVector(hid(), 'reducer: negative price clamps to 0', 50, [
  { type: 'addItem', gst: 5, id: 2 }, { type: 'setPrice', id: 2, value: -9 }])
reducerVector(hid(), 'reducer: qty to 0 removes line', 50, [
  { type: 'addItem', gst: 5, id: 3 }, { type: 'addItem', gst: 18, id: 4 },
  { type: 'setPrice', id: 4, value: 70 }, { type: 'setQty', id: 3, value: 0 }])
reducerVector(hid(), 'reducer: decrease then bill discount', 50, [
  { type: 'addItem', gst: 18, id: 5 }, { type: 'addItem', gst: 18, id: 5 },
  { type: 'addItem', gst: 12, id: 6 }, { type: 'decreaseQty', id: 5 },
  { type: 'setPrice', id: 5, value: 20 }, { type: 'setPrice', id: 6, value: 35 }],
  { billDiscount: '12.5' })

// ---- seeded random carts ----
const GST = [0, 5, 12, 18]
const target = 300
let r = 0
while (vectors.length < target) {
  const count = ri(0, 8)
  const lines = []
  for (let i = 0; i < count; i++) {
    const intQty = rnd() < 0.5
    lines.push(L(
      intQty ? String(ri(1, 20)) : dec(ri(1, 25000), 3),
      dec(rnd() < 0.1 ? 0 : ri(1, 60000), 2),
      rnd() < 0.55 ? '0' : dec(rnd() < 0.05 ? 10000 : ri(1, 6000), 2),
      pick(GST)))
  }
  const sum = lines.reduce((s, l) => s + Number(l.qty) * Number(l.price), 0)
  const mode = rnd() < 0.5 ? 'percent' : 'flat'
  const bd = rnd() < 0.3 ? '0'
    : mode === 'percent' ? dec(ri(1, 10000), 2)
    : dec(ri(1, Math.max(1, Math.round(sum * 100 * 1.2))), 2)
  const avail = ri(0, 500)
  const pts = rnd() < 0.4 ? 0 : ri(0, avail + 50)
  vector(`r${String(++r).padStart(3, '0')}`, {
    name: 'random', lines, discountType: mode, billDiscount: bd,
    points: String(pts), available: String(avail) })
}

const doc = { generator: 'tool/golden/gen_vectors.mjs', seed: 20261008,
  currency: 'INR', count: vectors.length, vectors }
const json = JSON.stringify(doc, null, 1) + '\n'
writeFileSync('test/fixtures/pricing_golden.json', json)
writeFileSync('test/fixtures/pricing_golden_data.g.dart',
  `// GENERATED by tool/golden/gen_vectors.mjs. Do not edit.\n` +
  `// ignore_for_file: lines_longer_than_80_chars\n` +
  `const String pricingGoldenJson = r'''${json}''';\n`)
const nz = vectors.filter((v) => v.negZero.length)
console.log(`wrote ${vectors.length} vectors; -0 outputs in ${nz.length}`,
  nz.map((v) => `${v.id}:${v.negZero}`).join(' '))
