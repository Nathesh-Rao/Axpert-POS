// The prototype's hold() and recall() rules and the discount drawer's number
// rules (plain Dart, VM and Chrome).
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/pricing_models.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/pos/models/held_bill.dart';
import 'package:pos_application/modules/pos/services/discount_rules.dart';
import 'package:pos_application/modules/pos/services/hold_recall_service.dart';
import 'package:pos_application/modules/products/models/product.dart';

Product _product(int id, {int stock = 10, int priceMinor = 4000}) => Product(
  id: id,
  name: 'P$id',
  code: 'C$id',
  barcode: 'B$id',
  price: Money(priceMinor, CurrencyRegistry.inr),
  category: 'c',
  sub: 's',
  stock: stock,
  gst: const Bp(1800),
  image: -1,
  favourite: false,
);

CartLine _line(Product p, int qtyMilli) =>
    CartLine(product: p, qty: Qty(qtyMilli), price: p.price, discount: Bp.zero);

void main() {
  const service = HoldRecallService();

  group('hold', () {
    test('ref is H plus the last six digits of the epoch milliseconds', () {
      final now = DateTime.fromMillisecondsSinceEpoch(
        1790000123456,
        isUtc: true,
      );
      expect(HoldRecallService.refFor(now), 'H123456');
      // Fewer than six digits are kept whole (as slice(-6) does).
      expect(
        HoldRecallService.refFor(DateTime.fromMillisecondsSinceEpoch(42)),
        'H42',
      );
    });

    test('hold keeps the cart and stamps an ISO time', () {
      final cart = Cart(lines: <CartLine>[_line(_product(1), 2000)]);
      final now = DateTime.utc(2026, 10, 8, 11, 16, 4, 123);
      final bill = service.hold(cart, now);
      expect(bill.cart, same(cart));
      expect(bill.time, '2026-10-08T11:16:04.123Z');
    });
  });

  group('recall', () {
    HeldBill bill(List<CartLine> lines) => HeldBill(
      ref: 'H1',
      time: '2026-10-08T00:00:00.000Z',
      cart: Cart(lines: lines, note: 'keep', reason: 'why'),
    );

    test('re-reads the product and clamps the qty to the current stock', () {
      final old = _product(1, stock: 10);
      final now = _product(1, stock: 3, priceMinor: 9900);
      final out = service.recall(
        bill(<CartLine>[_line(old, 5000)]),
        (id) => now,
      );
      final line = out.cart.lines.single;
      expect(line.product, same(now));
      expect(line.qty, const Qty(3000));
      // The line keeps its own price (`{...line, product, qty}`).
      expect(line.price, old.price);
      expect(out.cart.note, 'keep');
      expect(out.cart.reason, 'why');
      expect(out.missingProducts, isEmpty);
    });

    test('a fractional qty below the stock is kept', () {
      final p = _product(1, stock: 10);
      final out = service.recall(bill(<CartLine>[_line(p, 1500)]), (id) => p);
      expect(out.cart.lines.single.qty, const Qty(1500));
    });

    test('lines whose stock is now zero are dropped', () {
      final out = service.recall(
        bill(<CartLine>[_line(_product(1), 1000), _line(_product(2), 1000)]),
        (id) => id == 1 ? _product(1, stock: 0) : _product(2),
      );
      expect(out.cart.lines.map((l) => l.product.id), <int>[2]);
    });

    test('a missing product is dropped and reported, no crash (DEC-003)', () {
      final out = service.recall(
        bill(<CartLine>[_line(_product(1), 1000), _line(_product(2), 1000)]),
        (id) => id == 2 ? _product(2) : null,
      );
      expect(out.cart.lines.map((l) => l.product.id), <int>[2]);
      expect(out.missingProducts, <int>[1]);
    });
  });

  group('discount rules', () {
    final subtotal = const Money(4000, CurrencyRegistry.inr); // 40.00
    const percent = BillDiscountType.percent;
    const flat = BillDiscountType.flat;

    test('percent is clamped to 0..100 in basis points', () {
      expect(
        DiscountRules.clampScaled(percent, '12.5', subtotal: subtotal),
        1250,
      );
      expect(
        DiscountRules.clampScaled(percent, '150', subtotal: subtotal),
        10000,
      );
      expect(
        DiscountRules.clampScaled(percent, '100', subtotal: subtotal),
        10000,
      );
      expect(DiscountRules.clampScaled(percent, '-5', subtotal: subtotal), 0);
    });

    test('flat is clamped to the gross subtotal in minor units', () {
      expect(DiscountRules.clampScaled(flat, '25.5', subtotal: subtotal), 2550);
      expect(DiscountRules.clampScaled(flat, '99', subtotal: subtotal), 4000);
      expect(DiscountRules.clampScaled(flat, '40', subtotal: subtotal), 4000);
    });

    test('an empty field is zero', () {
      expect(DiscountRules.clampScaled(percent, '', subtotal: subtotal), 0);
      expect(DiscountRules.clampScaled(flat, '  ', subtotal: subtotal), 0);
    });

    test('shown: in-range text is left as typed, others are rewritten', () {
      String shown(BillDiscountType t, String x) =>
          DiscountRules.shown(t, x, subtotal: subtotal);
      expect(shown(percent, '5.'), '5.');
      expect(shown(percent, '12.50'), '12.50');
      expect(shown(percent, '.'), '.');
      expect(shown(percent, '150'), '100');
      expect(shown(flat, '99'), '40');
      expect(shown(flat, '40.001'), '40'); // rounds to 40.00 and is in range
      expect(shown(percent, ''), '0'); // React: an emptied number field is 0
    });

    test('apply keeps a number typed before the type switch (KG-122)', () {
      final c = CurrencyRegistry.inr;
      expect(
        DiscountRules.clampScaledUnbounded(percent, '500', currency: c),
        50000,
      );
      expect(
        DiscountRules.clampScaledUnbounded(flat, '500', currency: c),
        50000,
      );
      expect(DiscountRules.clampScaledUnbounded(flat, '', currency: c), 0);
    });

    test('toDiscount and textOf round-trip', () {
      final c = CurrencyRegistry.inr;
      final p = DiscountRules.toDiscount(percent, 1250, c);
      expect(p.type, percent);
      expect(p.percent, const Bp(1250));
      expect(DiscountRules.textOf(p, c), '12.5');
      final f = DiscountRules.toDiscount(flat, 2550, c);
      expect(f.flat, Money(2550, c));
      expect(DiscountRules.textOf(f, c), '25.5');
      expect(DiscountRules.textOf(const BillDiscount.none(), c), '0');
    });
  });
}
