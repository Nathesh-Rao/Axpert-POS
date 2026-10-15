import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/packaging/packaging_ref.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';

import '../../support/product_fixtures.dart';

void main() {
  const carton = PackagingRef(
    id: 'pk',
    unitName: 'Carton',
    quantityBaseMilli: 24000,
  );

  CartLine line({PackagingRef? packaging, int qty = 2000}) => CartLine(
    product: prod(1),
    qty: Qty(qty),
    price: const Money(96000, CurrencyRegistry.inr),
    discount: Bp.zero,
    packaging: packaging,
  );

  test('a line without packaging serializes exactly as before', () {
    expect(line().toJson().keys, [
      'product',
      'qtyMilli',
      'priceMinor',
      'discountBp',
    ]);
    expect(line().baseQty, const Qty(2000));
  });

  test('a packaging line round-trips and reports base units', () {
    final l = line(packaging: carton);
    final back = CartLine.fromJson(l.toJson());
    expect(back, l);
    expect(back.packaging, carton);
    expect(back.baseQty, const Qty(48000));
    expect(CartLine.fromJson(line().toJson()).packaging, isNull);
  });

  test('fractional packages round once to a milli-unit', () {
    expect(line(packaging: carton, qty: 1500).baseQty, const Qty(36000));
  });

  test('copyWith, withOffer and inCurrency keep the packaging', () {
    final l = line(packaging: carton);
    expect(l.copyWith(qty: const Qty(1000)).packaging, carton);
    expect(
      l
          .withOffer(
            const LineOffer(kind: 'promotion', name: 'x', savingMinor: 1),
          )
          .packaging,
      carton,
    );
    expect(l.inCurrency(CurrencyRegistry.inr).packaging, carton);
  });

  test('two lines differing only in packaging are not equal', () {
    expect(line(packaging: carton), isNot(line()));
  });
}
