import '../../../core/services/pricing/currency.dart';
import '../../../core/services/pricing/currency_registry.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../core/services/pricing/tax_split.dart';
import '../../pos/models/cart.dart';
import '../../pos/models/line_key.dart';

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

/// A completed sale (prototype `Sale`); `returned` maps a line key (product
/// and packaging, DEC-154) to returned milli-units of that line's unit.
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
    this.saleId,
    this.cashier,
    this.taxParts = const <TaxPart>[],
  });

  factory Sale.fromJson(
    Map<String, dynamic> json, {
    Currency currency = CurrencyRegistry.inr,
  }) => Sale(
    number: json['number'] as String,
    saleId: json['saleId'] as String?,
    cashier: json['cashier'] as String?,
    date: json['date'] as String,
    store: json['store'] as String,
    customer: json['customer'] as String,
    cart: Cart.fromJson(
      json['cart'] as Map<String, dynamic>,
      currency: currency,
    ),
    totals: SaleTotals.fromJson(
      json['totals'] as Map<String, dynamic>,
      currency: currency,
    ),
    mode: json['mode'] as String,
    tendered: Money(json['tenderedMinor'] as int, currency),
    change: Money(json['changeMinor'] as int, currency),
    returned: <LineKey, Qty>{
      for (final e in (json['returned'] as Map<String, dynamic>).entries)
        LineKey.parse(e.key): Qty(e.value as int),
    },
    taxParts: <TaxPart>[
      for (final p in (json['taxParts'] as List<dynamic>? ?? const []))
        TaxPart(
          (p as Map<String, dynamic>)['label'] as String,
          Money(p['minor'] as int, currency),
        ),
    ],
  );

  final String number;

  /// UUID v4 of a NEW sale (DEC-123); null for sales stored before it existed
  /// and for draft receipts. Display and lookups still use [number].
  final String? saleId;
  final String date;
  final String store;

  /// Display name of the cashier at the time of the sale; null on sales stored
  /// before sessions existed.
  final String? cashier;
  final String customer;
  final Cart cart;
  final SaleTotals totals;
  final String mode;
  final Money tendered;
  final Money change;
  final Map<LineKey, Qty> returned;

  /// Tax lines (label and amount) as printed when the sale was made; empty on
  /// older sales and for one-line tax (labels then come from the current
  /// setup, KG-216).
  final List<TaxPart> taxParts;

  Sale copyWith({
    Map<LineKey, Qty>? returned,
    String? date,
    List<TaxPart>? taxParts,
  }) => Sale(
    number: number,
    saleId: saleId,
    cashier: cashier,
    date: date ?? this.date,
    store: store,
    customer: customer,
    cart: cart,
    totals: totals,
    mode: mode,
    tendered: tendered,
    change: change,
    returned: returned ?? this.returned,
    taxParts: taxParts ?? this.taxParts,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'number': number,
    if (saleId != null) 'saleId': saleId,
    if (cashier != null) 'cashier': cashier,
    'date': date,
    'store': store,
    'customer': customer,
    'cart': cart.toJson(),
    'totals': totals.toJson(),
    'mode': mode,
    'tenderedMinor': tendered.minor,
    'changeMinor': change.minor,
    'returned': <String, int>{
      for (final e in returned.entries) e.key.text: e.value.milli,
    },
    if (taxParts.isNotEmpty)
      'taxParts': <Map<String, dynamic>>[
        for (final p in taxParts)
          <String, dynamic>{'label': p.label, 'minor': p.amount.minor},
      ],
  };
}
