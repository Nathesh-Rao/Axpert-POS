import '../../../core/services/pricing/basis_points.dart';
import '../../../core/services/pricing/currency.dart';
import '../../../core/services/pricing/currency_registry.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/pricing_models.dart';
import '../../../core/services/pricing/qty.dart';
import '../../customers/models/customer.dart';
import '../../products/models/product.dart';
import 'cart_line.dart';

enum SaleType {
  cash('Cash'),
  credit('Credit');

  const SaleType(this.json);

  final String json;

  static SaleType fromJson(String value) =>
      values.firstWhere((t) => t.json == value, orElse: () => cash);
}

/// The cart (prototype `Cart` plus its `cartReducer` rules). Immutable: every
/// rule returns a new cart, or `this` when the prototype returns the same state.
class Cart {
  const Cart({
    this.lines = const <CartLine>[],
    this.customer = Customer.walkInId,
    this.saleType = SaleType.cash,
    this.billDiscount = const BillDiscount.none(),
    this.reason = '',
    this.points = 0,
    this.note = '',
  });

  factory Cart.fromJson(
    Map<String, dynamic> json, {
    Currency currency = CurrencyRegistry.inr,
  }) {
    final flat = json['discountType'] == 'flat';
    return Cart(
      lines: <CartLine>[
        for (final line in json['lines'] as List<dynamic>)
          CartLine.fromJson(line as Map<String, dynamic>, currency: currency),
      ],
      customer: json['customer'] as String,
      saleType: SaleType.fromJson(json['saleType'] as String),
      billDiscount: flat
          ? BillDiscount.flat(Money(json['billDiscountMinor'] as int, currency))
          : BillDiscount.percent(Bp(json['billDiscountBp'] as int)),
      reason: json['reason'] as String,
      points: json['points'] as int,
      note: json['note'] as String,
    );
  }

  static const Cart empty = Cart();

  final List<CartLine> lines;
  final String customer;
  final SaleType saleType;
  final BillDiscount billDiscount;
  final String reason;

  /// Whole points to redeem.
  final int points;
  final String note;

  bool get isActive => lines.isNotEmpty;

  CartLine? lineOf(int productId) {
    for (final line in lines) {
      if (line.product.id == productId) return line;
    }
    return null;
  }

  Cart copyWith({
    List<CartLine>? lines,
    String? customer,
    SaleType? saleType,
    BillDiscount? billDiscount,
    String? reason,
    int? points,
    String? note,
  }) => Cart(
    lines: lines ?? this.lines,
    customer: customer ?? this.customer,
    saleType: saleType ?? this.saleType,
    billDiscount: billDiscount ?? this.billDiscount,
    reason: reason ?? this.reason,
    points: points ?? this.points,
    note: note ?? this.note,
  );

  // ---- cartReducer rules ----

  /// `addItem`: blocked when quantity + 1 would exceed the product's stock.
  Cart addItem(Product product) {
    final existing = lineOf(product.id);
    final next = (existing?.qty ?? Qty.zero) + Qty.units(1);
    if (next > product.stockQty) return this;
    if (existing == null) {
      return copyWith(lines: <CartLine>[...lines, CartLine.of(product)]);
    }
    return _mapLine(product.id, (line) => line.copyWith(qty: next));
  }

  /// `setQty` (also increase/decrease): clamped to 0..stock of the line's
  /// snapshot, lines at 0 are dropped.
  Cart setQty(int productId, Qty qty) {
    final mapped = <CartLine>[];
    for (final line in lines) {
      if (line.product.id != productId) {
        mapped.add(line);
        continue;
      }
      var clamped = qty < Qty.zero ? Qty.zero : qty;
      if (clamped > line.product.stockQty) clamped = line.product.stockQty;
      if (clamped > Qty.zero) mapped.add(line.copyWith(qty: clamped));
    }
    return copyWith(lines: mapped);
  }

  /// `setPrice`: minimum 0.
  Cart setPrice(int productId, Money price) => _mapLine(
    productId,
    (line) => line.copyWith(
      price: price.isNegative ? Money.zero(price.currency) : price,
    ),
  );

  /// `setLineDiscount`: clamped to 0..100 %.
  Cart setLineDiscount(int productId, Bp discount) => _mapLine(
    productId,
    (line) => line.copyWith(discount: discount.clamp(Bp.zero, Bp.full)),
  );

  Cart removeLine(int productId) => copyWith(
    lines: <CartLine>[
      for (final line in lines)
        if (line.product.id != productId) line,
    ],
  );

  /// `restoreLine`: only when the product is not in the cart again.
  Cart restoreLine(CartLine line) => lineOf(line.product.id) != null
      ? this
      : copyWith(lines: <CartLine>[...lines, line]);

  Cart _mapLine(int productId, CartLine Function(CartLine) change) => copyWith(
    lines: <CartLine>[
      for (final line in lines)
        line.product.id == productId ? change(line) : line,
    ],
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'lines': <Map<String, dynamic>>[for (final l in lines) l.toJson()],
    'customer': customer,
    'saleType': saleType.json,
    'discountType': billDiscount.type == BillDiscountType.flat
        ? 'flat'
        : 'percent',
    'billDiscountBp': billDiscount.percent.value,
    'billDiscountMinor': billDiscount.flat?.minor ?? 0,
    'reason': reason,
    'points': points,
    'note': note,
  };
}
