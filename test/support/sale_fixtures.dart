import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/sales/models/sale.dart';

/// A completed sale with only the fields the Sales and Reports pages read.
Sale testSale({
  required String number,
  required DateTime at,
  String customer = 'Walk-in Customer',
  String mode = 'Cash',
  int totalMinor = 10000,
}) {
  final total = Money(totalMinor, CurrencyRegistry.inr);
  const zero = Money.zero(CurrencyRegistry.inr);
  return Sale(
    number: number,
    date: at.toUtc().toIso8601String(),
    store: 'Maison Galaxy',
    customer: customer,
    cart: const Cart(),
    totals: SaleTotals(
      items: 1,
      qty: const Qty(1000),
      value: total,
      subtotal: total,
      discount: zero,
      tax: zero,
      points: zero,
      total: total,
    ),
    mode: mode,
    tendered: total,
    change: zero,
    returned: const <int, Qty>{},
  );
}
