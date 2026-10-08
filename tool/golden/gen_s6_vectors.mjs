// Generates test/fixtures/s6_golden.json (and the .g.dart copy) for the S6
// formula verification: refund amount, forex card, points clamp.
//
// Usage (from pos_application/):
//   npx --yes esbuild ../reference_react/src/data.ts --format=esm --outfile=$TMP/data.mjs
//   node tool/golden/gen_s6_vectors.mjs $TMP/data.mjs
// Nothing is written into reference_react/. Nothing is installed.
//
// Points vectors use React's REAL exported calculate(). The refund amount and
// the forex figure are inline in App.tsx (not exported), so their expressions
// are transcribed VERBATIM below with the App.tsx line numbers; the generator
// first checks that App.tsx still contains the same text (whitespace ignored),
// and the numbers are then produced by the real JS engine (float arithmetic,
// toFixed, money() from data.ts).
import { readFileSync, writeFileSync } from 'node:fs'
import { pathToFileURL } from 'node:url'
import { resolve } from 'node:path'

const dataPath = process.argv[2]
if (!dataPath) throw new Error('pass the transpiled data.mjs path')
const { calculate, money } = await import(pathToFileURL(resolve(dataPath)).href)

// ---- the verbatim App.tsx expressions -----------------------------------
const app = readFileSync('../reference_react/src/App.tsx', 'utf8')
const squash = (s) => s.replace(/\s+/g, '')
const REFUND_SRC = `const share = returnSale.totals.value
        ? (line.qty * line.price) / returnSale.totals.value
        : 0
      return sum + (returnSale.totals.total * share * qty) / line.qty`          // App.tsx 626-629
const FOREX_SRC = `rate > 0 ? totals.total / rate : 0`                              // App.tsx 182
for (const [name, src] of [['refund', REFUND_SRC], ['forex', FOREX_SRC]]) {
  if (!squash(app).includes(squash(src))) {
    throw new Error(`App.tsx no longer contains the ${name} expression`)
  }
}
const FOREX_FIXED = squash(app).includes('<span>{converted.toFixed(2)}</span>')
if (!FOREX_FIXED) throw new Error('App.tsx no longer shows converted.toFixed(2)')

let seed = 20261009
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
  const s = String(Math.abs(n)).padStart(scale + 1, '0')
  return (n < 0 ? '-' : '') + (scale ? `${s.slice(0, -scale)}.${s.slice(-scale)}` : s)
}
const GST = [0, 5, 12, 18]
const product = (gst, id) => ({
  id, name: `P${id}`, code: '', barcode: '', price: 0, category: '', sub: '',
  stock: 1e9, gst, image: 0, favourite: false,
})
const moneyDigits = (x) => money(x).replace('₹', '').replace(/,/g, '')

// ---- refund -------------------------------------------------------------
const refunds = []
function refundVector(id, name, specLines, billDiscount = '0', discountType = 'percent', picks) {
  const cart = {
    lines: specLines.map((l, i) => ({
      product: product(Number(l.gst), i + 1), qty: Number(l.qty),
      price: Number(l.price), discount: Number(l.discount ?? '0'),
    })),
    customer: 'walk', saleType: 'Cash', discountType,
    billDiscount: Number(billDiscount), points: 0, reason: '', note: '',
  }
  const t = calculate(cart, 0)
  // the sale as stored: rounded totals, lines as in the cart
  const returned = picks.map((p) => ({ line: p.line, qty: p.qty }))
  const returnSale = { totals: { value: t.value, total: t.total }, cart }
  const entries = returned.map((p) => [String(cart.lines[p.line].product.id), Number(p.qty)])
    .filter(([, q]) => q > 0)
  // ---- VERBATIM (App.tsx 625-629) ----
  const refundAmount = entries.reduce((sum, [id, qty]) => {
    const line = returnSale.cart.lines.find((item) => item.product.id === Number(id))
    const share = returnSale.totals.value
      ? (line.qty * line.price) / returnSale.totals.value
      : 0
    return sum + (returnSale.totals.total * share * qty) / line.qty
  }, 0)
  refunds.push({
    id, name,
    lines: specLines.map((l) => ({
      qty: l.qty, price: l.price, discount: l.discount ?? '0', gst: String(l.gst),
    })),
    discountType, billDiscount,
    saleValue: t.value.toFixed(2), saleTotal: t.total.toFixed(2),
    returns: returned.map((p) => ({ line: p.line, qty: p.qty })),
    expected: { amount: moneyDigits(refundAmount), raw: refundAmount },
  })
}
const L = (qty, price, discount, gst) => ({ qty, price, discount, gst })
let rn = 0
const rid = () => `f${String(++rn).padStart(3, '0')}`
refundVector(rid(), 'one line, half returned', [L('2', '50.00', '0', 18)], '0', 'percent', [{ line: 0, qty: '1' }])
refundVector(rid(), 'full return', [L('3', '40.00', '0', 18)], '0', 'percent', [{ line: 0, qty: '3' }])
refundVector(rid(), 'line discount ignored by the share', [L('4', '25.00', '20', 12), L('1', '99.00', '0', 12)], '0', 'percent', [{ line: 0, qty: '2' }])
refundVector(rid(), 'bill discount', [L('2', '60.00', '0', 5), L('3', '10.00', '0', 18)], '10', 'percent', [{ line: 1, qty: '1' }])
refundVector(rid(), 'flat discount', [L('2', '60.00', '0', 5), L('3', '10.00', '0', 18)], '25', 'flat', [{ line: 0, qty: '1' }, { line: 1, qty: '2' }])
refundVector(rid(), 'fractional qty', [L('1.375', '110.00', '0', 12), L('0.333', '100.00', '0', 18)], '0', 'percent', [{ line: 0, qty: '0.5' }, { line: 1, qty: '0.111' }])
refundVector(rid(), 'zero value sale', [L('5', '0.00', '0', 18)], '0', 'percent', [{ line: 0, qty: '2' }])
refundVector(rid(), 'thirds', [L('3', '10.00', '0', 0)], '0', 'percent', [{ line: 0, qty: '1' }])
refundVector(rid(), 'tiny', [L('1000', '0.01', '0', 18)], '0', 'percent', [{ line: 0, qty: '1' }])
refundVector(rid(), 'large lakh', [L('1000', '12345.67', '0', 12)], '5', 'percent', [{ line: 0, qty: '333' }])
for (let i = 0; i < 110; i++) {
  const n = ri(1, 4)
  const lines = []
  for (let k = 0; k < n; k++) {
    lines.push(L(rnd() < 0.5 ? String(ri(1, 20)) : dec(ri(1, 25000), 3),
      dec(ri(1, 60000), 2), rnd() < 0.55 ? '0' : dec(ri(1, 6000), 2), pick(GST)))
  }
  const mode = rnd() < 0.5 ? 'percent' : 'flat'
  const sum = lines.reduce((s, l) => s + Number(l.qty) * Number(l.price), 0)
  const bd = rnd() < 0.4 ? '0' : mode === 'percent' ? dec(ri(1, 4000), 2)
    : dec(ri(1, Math.max(1, Math.round(sum * 30))), 2)
  const picks = []
  lines.forEach((l, idx) => {
    if (rnd() < 0.6) {
      const milli = Math.round(Number(l.qty) * 1000)
      const rq = rnd() < 0.3 ? milli : ri(1, milli)
      picks.push({ line: idx, qty: dec(rq, 3).replace(/\.?0+$/, '') || '0' })
    }
  })
  if (!picks.length) picks.push({ line: 0, qty: lines[0].qty })
  refundVector(rid(), 'random', lines, bd, mode, picks)
}

// ---- forex --------------------------------------------------------------
const forex = []
function forexVector(id, name, total, rate) {
  const t = Number(total), r = Number(rate)
  // ---- VERBATIM (App.tsx 181-183 and 1639/1653) ----
  const converted = r > 0 ? t / r : 0
  forex.push({ id, name, total, rate, expected: converted.toFixed(2) })
}
let fn = 0
const fid = () => `x${String(++fn).padStart(3, '0')}`
forexVector(fid(), 'default rate exact', '856.10', '8.561')
forexVector(fid(), 'default rate', '21.00', '8.561')
forexVector(fid(), 'zero rate', '100.00', '0')
forexVector(fid(), 'negative rate', '100.00', '-2')
forexVector(fid(), 'zero total', '0.00', '8.561')
forexVector(fid(), 'thirds', '100.00', '3')
forexVector(fid(), 'tie 0.505', '1.01', '2')
forexVector(fid(), 'tie 5.075', '10.15', '2')
forexVector(fid(), 'tie 0.005', '0.01', '2')
forexVector(fid(), 'tiny rate', '1.00', '0.001')
forexVector(fid(), 'large', '9999999.99', '8.561')
for (const rate of ['2', '4', '0.5', '8', '1.6', '3.2', '0.25', '1.25', '6.4']) {
  for (let i = 0; i < 6; i++) forexVector(fid(), `tie-prone rate ${rate}`, dec(ri(1, 200000), 2), rate)
}
for (let i = 0; i < 60; i++) {
  forexVector(fid(), 'random', dec(ri(0, 2000000), 2),
    rnd() < 0.1 ? '8.561' : dec(ri(1, 99999), 3))
}

// ---- points clamp (real calculate) ---------------------------------------
const points = []
function pointsVector(id, name, specLines, discountType, billDiscount, pts, available) {
  const cart = {
    lines: specLines.map((l, i) => ({
      product: product(Number(l.gst), i + 1), qty: Number(l.qty),
      price: Number(l.price), discount: Number(l.discount ?? '0'),
    })),
    customer: 'c', saleType: 'Cash', discountType,
    billDiscount: Number(billDiscount), points: Number(pts), reason: '', note: '',
  }
  const t = calculate(cart, Number(available))
  points.push({
    id, name,
    lines: specLines.map((l) => ({
      qty: l.qty, price: l.price, discount: l.discount ?? '0', gst: String(l.gst),
    })),
    discountType, billDiscount, points: String(pts), available: String(available),
    expected: {
      items: t.items, qtyMilli: Math.round(t.qty * 1000),
      value: t.value.toFixed(2), subtotal: t.subtotal.toFixed(2),
      discount: t.discount.toFixed(2), tax: t.tax.toFixed(2),
      points: t.points.toFixed(2), total: t.total.toFixed(2),
    },
  })
}
let pn = 0
const pid = () => `p${String(++pn).padStart(3, '0')}`
pointsVector(pid(), 'no points', [L('1', '40.00', '0', 18)], 'percent', '0', 0, 100)
pointsVector(pid(), 'requested above available', [L('10', '40.00', '0', 18)], 'percent', '0', 300, 120)
pointsVector(pid(), 'requested above fractional payable', [L('1', '40.00', '0', 18)], 'percent', '0', 500, 1000)
pointsVector(pid(), 'payable 47.20, requested 500', [L('1', '40.00', '0', 18)], 'percent', '0', 500, 500)
pointsVector(pid(), 'requested equals whole payable', [L('1', '40.00', '0', 18)], 'percent', '0', 47, 47)
pointsVector(pid(), 'requested one below payable', [L('1', '40.00', '0', 18)], 'percent', '0', 46, 100)
pointsVector(pid(), 'available zero', [L('1', '40.00', '0', 18)], 'percent', '0', 20, 0)
pointsVector(pid(), 'bill discount shrinks payable', [L('3', '85.00', '5', 12)], 'percent', '10', 1000, 1000)
pointsVector(pid(), 'flat discount and points', [L('3', '85.00', '5', 12)], 'flat', '100', 1000, 1000)
pointsVector(pid(), 'empty cart with points', [], 'percent', '0', 10, 10)
pointsVector(pid(), 'zero price', [L('5', '0.00', '0', 18)], 'percent', '0', 10, 10)
pointsVector(pid(), 'points cover everything', [L('1', '1.00', '0', 0)], 'percent', '0', 5, 5)
for (let i = 0; i < 60; i++) {
  const n = ri(1, 3)
  const lines = []
  for (let k = 0; k < n; k++) {
    lines.push(L(rnd() < 0.5 ? String(ri(1, 10)) : dec(ri(1, 9000), 3),
      dec(ri(1, 30000), 2), rnd() < 0.6 ? '0' : dec(ri(1, 3000), 2), pick(GST)))
  }
  const mode = rnd() < 0.5 ? 'percent' : 'flat'
  const sum = lines.reduce((s, l) => s + Number(l.qty) * Number(l.price), 0)
  const bd = rnd() < 0.4 ? '0' : mode === 'percent' ? dec(ri(1, 5000), 2)
    : dec(ri(1, Math.max(1, Math.round(sum * 40))), 2)
  const avail = ri(0, 800)
  const req = pick([0, ri(0, avail + 100), avail, avail + 1, ri(0, 1000)])
  pointsVector(pid(), 'random', lines, mode, bd, req, avail)
}

const doc = { generator: 'tool/golden/gen_s6_vectors.mjs', seed: 20261009,
  currency: 'INR', refunds, forex, points }
const json = JSON.stringify(doc, null, 1) + '\n'
writeFileSync('test/fixtures/s6_golden.json', json)
writeFileSync('test/fixtures/s6_golden_data.g.dart',
  `// GENERATED by tool/golden/gen_s6_vectors.mjs. Do not edit.\n` +
  `// ignore_for_file: lines_longer_than_80_chars\n` +
  `const String s6GoldenJson = r'''${json}''';\n`)
console.log(`refunds ${refunds.length}, forex ${forex.length}, points ${points.length}`)
