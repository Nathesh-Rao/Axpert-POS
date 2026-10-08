import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/mock/seed_products.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/line_math.dart';

void main() {
  final products = SeedProducts.products();
  final lays = products[5];
  final limited = products[14]; // stock 8

  test('addItem adds, then increments', () {
    final once = Cart.empty.addItem(lays);
    expect(once.lines.single.qty, Qty.units(1));
    expect(once.lines.single.price, lays.price);
    expect(once.addItem(lays).lines.single.qty, Qty.units(2));
  });

  test('addItem is blocked when quantity + 1 would exceed stock', () {
    var cart = Cart.empty;
    for (var i = 0; i < 8; i++) {
      cart = cart.addItem(limited);
    }
    expect(cart.lines.single.qty, Qty.units(8));
    expect(identical(cart.addItem(limited), cart), isTrue);
  });

  test('fractional quantity counts toward the stock limit', () {
    var cart = Cart.empty.addItem(limited).setQty(limited.id, const Qty(7500));
    expect(cart.addItem(limited).lines.single.qty, const Qty(7500));
    cart = cart.setQty(limited.id, const Qty(7000)).addItem(limited);
    expect(cart.lines.single.qty, Qty.units(8));
  });

  test('setQty clamps to stock and removes at zero or below', () {
    final cart = Cart.empty.addItem(limited);
    expect(
      cart.setQty(limited.id, Qty.units(99)).lines.single.qty,
      Qty.units(8),
    );
    expect(cart.setQty(limited.id, Qty.zero).lines, isEmpty);
    expect(cart.setQty(limited.id, const Qty(-5)).lines, isEmpty);
    expect(
      cart.setQty(limited.id, const Qty(1)).lines.single.qty,
      const Qty(1),
    );
  });

  test('price has a minimum of 0, discount is clamped to 0-100 %', () {
    final cart = Cart.empty.addItem(lays);
    expect(
      cart
          .setPrice(lays.id, const Money(-5, CurrencyRegistry.inr))
          .lines
          .single
          .price
          .minor,
      0,
    );
    expect(
      cart
          .setPrice(lays.id, const Money(2550, CurrencyRegistry.inr))
          .lines
          .single
          .price
          .minor,
      2550,
    );
    expect(
      cart.setLineDiscount(lays.id, const Bp(15000)).lines.single.discount,
      Bp.full,
    );
    expect(
      cart.setLineDiscount(lays.id, const Bp(-1)).lines.single.discount,
      Bp.zero,
    );
    expect(
      cart.setLineDiscount(lays.id, const Bp(1250)).lines.single.discount,
      const Bp(1250),
    );
  });

  test('removeLine and restoreLine (not twice)', () {
    final cart = Cart.empty.addItem(lays).addItem(products[0]);
    final line = cart.lines.first;
    final removed = cart.removeLine(lays.id);
    expect(removed.lines.length, 1);
    final restored = removed.restoreLine(line);
    expect(restored.lines.map((l) => l.product.id), [0, 5]);
    expect(identical(restored.restoreLine(line), restored), isTrue);
  });

  test('line total: line discount first, exact then rounded once', () {
    final line = Cart.empty
        .addItem(lays)
        .setQty(lays.id, const Qty(2500))
        .setLineDiscount(lays.id, const Bp(1250))
        .lines
        .single;
    // 2.5 x 20.00 x 0.875 = 43.75
    expect(LineMath.lineTotal(line).minor, 4375);
  });
}
