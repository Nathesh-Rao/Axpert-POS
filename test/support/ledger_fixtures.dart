import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/pricing_models.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/sales/models/sale.dart';

import 'product_fixtures.dart';

Money _m(int minor) => Money(minor, CurrencyRegistry.inr);

/// A sale with real lines (one per id in [productIds], quantity 2 each), a
/// bill discount, points, a note and a customer id, for persistence tests.
Sale ledgerSale(
  String number, {
  String? saleId,
  List<int> productIds = const <int>[1, 2],
  Map<int, Qty> returned = const <int, Qty>{},
  String customerId = 'walk',
  String customerName = 'Walk-in Customer',
  String mode = 'Cash',
  bool flatDiscount = false,
  String date = '2026-10-12T10:00:00.000Z',
}) {
  final lines = <CartLine>[
    for (final id in productIds)
      CartLine(
        product: prod(id, gstBp: id == 2 ? 550 : 1800, favourite: id == 1),
        qty: const Qty(2000),
        price: _m(4000 + id * 100),
        discount: id == 2 ? const Bp(500) : Bp.zero,
      ),
  ];
  return Sale(
    number: number,
    saleId: saleId,
    date: date,
    store: 'Maison Galaxy',
    customer: customerName,
    cart: Cart(
      lines: lines,
      customer: customerId,
      saleType: mode == 'Credit' ? SaleType.credit : SaleType.cash,
      billDiscount: flatDiscount
          ? BillDiscount.flat(_m(300))
          : const BillDiscount.percent(Bp(250)),
      reason: 'loyal',
      points: 10,
      note: 'n-$number',
    ),
    totals: SaleTotals(
      items: lines.length,
      qty: Qty(2000 * lines.length),
      value: _m(20000),
      subtotal: _m(19000),
      discount: _m(1000),
      tax: _m(3420),
      points: _m(1000),
      total: _m(21420),
    ),
    mode: mode,
    tendered: _m(25000),
    change: _m(3580),
    returned: returned,
  );
}
