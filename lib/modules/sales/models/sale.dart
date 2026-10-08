import '../../../core/services/pricing/currency.dart';
import '../../../core/services/pricing/currency_registry.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/qty.dart';
import '../../pos/models/cart.dart';

/// Rounded totals stored with a sale (prototype `Totals`).
class SaleTotals {
  const SaleTotals({
    required this.items,
    required this.qty,
    required this.value,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.points,
    required this.total,
  });

  factory SaleTotals.fromJson(
    Map<String, dynamic> json, {
    Currency currency = CurrencyRegistry.inr,
  }) {
    Money m(String key) => Money(json[key] as int, currency);
    return SaleTotals(
      items: json['items'] as int,
      qty: Qty(json['qtyMilli'] as int),
      value: m('valueMinor'),
      subtotal: m('subtotalMinor'),
      discount: m('discountMinor'),
      tax: m('taxMinor'),
      points: m('pointsMinor'),
      total: m('totalMinor'),
    );
  }

  final int items;
  final Qty qty;
  final Money value;
  final Money subtotal;
  final Money discount;
  final Money tax;
  final Money points;
  final Money total;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'items': items,
    'qtyMilli': qty.milli,
    'valueMinor': value.minor,
    'subtotalMinor': subtotal.minor,
    'discountMinor': discount.minor,
    'taxMinor': tax.minor,
    'pointsMinor': points.minor,
    'totalMinor': total.minor,
  };
}

/// A completed sale (prototype `Sale`); `returned` maps product id to
/// returned milli-units.
class Sale {
  const Sale({
    required this.number,
    required this.date,
    required this.store,
    required this.customer,
    required this.cart,
    required this.totals,
    required this.mode,
    required this.tendered,
    required this.change,
    required this.returned,
  });

  factory Sale.fromJson(
    Map<String, dynamic> json, {
    Currency currency = CurrencyRegistry.inr,
  }) => Sale(
    number: json['number'] as String,
    date: json['date'] as String,
    store: json['store'] as String,
    customer: json['customer'] as String,
    cart: Cart.fromJson(json['cart'] as Map<String, dynamic>),
    totals: SaleTotals.fromJson(
      json['totals'] as Map<String, dynamic>,
      currency: currency,
    ),
    mode: json['mode'] as String,
    tendered: Money(json['tenderedMinor'] as int, currency),
    change: Money(json['changeMinor'] as int, currency),
    returned: <int, Qty>{
      for (final e in (json['returned'] as Map<String, dynamic>).entries)
        int.parse(e.key): Qty(e.value as int),
    },
  );

  final String number;
  final String date;
  final String store;
  final String customer;
  final Cart cart;
  final SaleTotals totals;
  final String mode;
  final Money tendered;
  final Money change;
  final Map<int, Qty> returned;

  Sale copyWith({Map<int, Qty>? returned}) => Sale(
    number: number,
    date: date,
    store: store,
    customer: customer,
    cart: cart,
    totals: totals,
    mode: mode,
    tendered: tendered,
    change: change,
    returned: returned ?? this.returned,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'number': number,
    'date': date,
    'store': store,
    'customer': customer,
    'cart': cart.toJson(),
    'totals': totals.toJson(),
    'mode': mode,
    'tenderedMinor': tendered.minor,
    'changeMinor': change.minor,
    'returned': <String, int>{
      for (final e in returned.entries) '${e.key}': e.value.milli,
    },
  };
}
