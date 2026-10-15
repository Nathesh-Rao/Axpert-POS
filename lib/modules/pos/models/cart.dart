import '../../../core/services/pricing/basis_points.dart';
import '../../../core/services/pricing/currency.dart';
import '../../../core/services/pricing/currency_registry.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/pricing_models.dart';
import '../../../core/services/pricing/qty.dart';
import '../../customers/models/customer.dart';
import '../../../features/products/domain/entities/product.dart';
import '../../../core/services/packaging/packaging_ref.dart';
import '../../../core/services/packaging/packaging_service.dart';
import 'cart_line.dart';
import 'line_key.dart';

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
    this.storeId,
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
      storeId: json['storeId'] as String?,
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

  /// Store the cart was filled in (scoped mode only); null otherwise. A saved
  /// cart of another store is dropped at sign-in.
  final String? storeId;

  bool get isActive => lines.isNotEmpty;

  CartLine? lineOf(LineKey key) {
    for (final line in lines) {
      if (line.key == key) return line;
    }
    return null;
  }

  /// Base units of [productId] across all its lines (stock checks), without
  /// the line [except].
  Qty baseQtyOf(int productId, {LineKey? except}) {
    var milli = 0;
    for (final line in lines) {
      if (line.product.id != productId || line.key == except) continue;
      milli += line.baseQty.milli;
    }
    return Qty(milli);
  }

  Cart copyWith({
    List<CartLine>? lines,
    String? customer,
    SaleType? saleType,
    BillDiscount? billDiscount,
    String? reason,
    int? points,
    String? note,
    String? storeId,
  }) => Cart(
    lines: lines ?? this.lines,
    customer: customer ?? this.customer,
    saleType: saleType ?? this.saleType,
    billDiscount: billDiscount ?? this.billDiscount,
    reason: reason ?? this.reason,
    points: points ?? this.points,
    note: note ?? this.note,
    storeId: storeId ?? this.storeId,
  );

  /// The same cart priced in [currency] (same minor units).
  Cart inCurrency(Currency currency) => Cart(
    lines: <CartLine>[for (final l in lines) l.inCurrency(currency)],
    customer: customer,
    saleType: saleType,
    billDiscount: billDiscount.flat == null
        ? billDiscount
        : BillDiscount.flat(Money(billDiscount.flat!.minor, currency)),
    reason: reason,
    points: points,
    note: note,
    storeId: storeId,
  );

  // ---- cartReducer rules ----

  static int _factor(PackagingRef? packaging) =>
      packaging?.quantityBaseMilli ?? 1000;

  /// Most packages of the line [key] the stock allows next to the other
  /// lines of the same product (base units summed across lines, DEC-154).
  Qty _maxQty(CartLine line, Qty wanted) {
    final left =
        line.product.stockQty.milli -
        baseQtyOf(line.product.id, except: line.key).milli;
    return Qty(
      const PackagingService().maxPackagesMilli(
        left,
        _factor(line.packaging),
        whole: wanted.milli % 1000 == 0,
      ),
    );
  }

  /// `addItem`: blocked when one more unit (one package) would take the base
  /// quantity of the product over its stock. [packaging] and its package
  /// [price] make a packaged line; without them the base-unit line.
  Cart addItem(Product product, {PackagingRef? packaging, Money? price}) {
    final key = LineKey(product.id, packaging?.id);
    final existing = lineOf(key);
    final used = baseQtyOf(product.id).milli;
    if (used + _factor(packaging) > product.stockQty.milli) return this;
    if (existing == null) {
      return copyWith(
        lines: <CartLine>[
          ...lines,
          CartLine.of(product, packaging: packaging, price: price),
        ],
      );
    }
    return _mapLine(key, (line) => line.copyWith(qty: line.qty + Qty.units(1)));
  }

  /// `setQty` (also increase/decrease): clamped to 0..stock of the line's
  /// snapshot, lines at 0 are dropped.
  Cart setQty(LineKey key, Qty qty) {
    final mapped = <CartLine>[];
    for (final line in lines) {
      if (line.key != key) {
        mapped.add(line);
        continue;
      }
      var clamped = qty < Qty.zero ? Qty.zero : qty;
      final max = _maxQty(line, clamped);
      if (clamped > max) clamped = max;
      if (clamped > Qty.zero) mapped.add(line.copyWith(qty: clamped));
    }
    return copyWith(lines: mapped);
  }

  /// `setPrice`: minimum 0.
  Cart setPrice(LineKey key, Money price) => _mapLine(
    key,
    (line) => line.copyWith(
      price: price.isNegative ? Money.zero(price.currency) : price,
    ),
  );

  /// `setLineDiscount`: clamped to 0..100 %.
  Cart setLineDiscount(LineKey key, Bp discount) => _mapLine(
    key,
    (line) => line.copyWith(discount: discount.clamp(Bp.zero, Bp.full)),
  );

  Cart removeLine(LineKey key) => copyWith(
    lines: <CartLine>[
      for (final line in lines)
        if (line.key != key) line,
    ],
  );

  /// `restoreLine`: only when the line (product and packaging) is not in the
  /// cart again.
  Cart restoreLine(CartLine line) => lineOf(line.key) != null
      ? this
      : copyWith(lines: <CartLine>[...lines, line]);

  /// Sells the line [key] in another unit ([packaging] null = base unit) at
  /// [price] (that unit's price): same quantity number, manual price and
  /// line discount reset to the new unit's (DEC-154). Merges into the
  /// existing line of that unit; blocked (returns `this`) when the stock does
  /// not allow it.
  Cart changeUnit(LineKey key, PackagingRef? packaging, Money price) {
    final line = lineOf(key);
    if (line == null || line.packaging?.id == packaging?.id) return this;
    final target = LineKey(key.productId, packaging?.id);
    final existing = lineOf(target);
    final qty = line.qty + (existing?.qty ?? Qty.zero);
    final moved = CartLine(
      product: line.product,
      qty: qty,
      price: existing?.price ?? price,
      discount: existing?.discount ?? Bp.zero,
      packaging: packaging,
    );
    final others =
        baseQtyOf(key.productId, except: key).milli -
        (existing?.baseQty.milli ?? 0);
    if (others + moved.baseQty.milli > line.product.stockQty.milli) return this;
    final next = <CartLine>[];
    for (final l in lines) {
      if (l.key == key) {
        if (existing == null) next.add(moved);
      } else if (l.key == target) {
        next.add(moved);
      } else {
        next.add(l);
      }
    }
    return copyWith(lines: next);
  }

  Cart _mapLine(LineKey key, CartLine Function(CartLine) change) => copyWith(
    lines: <CartLine>[
      for (final line in lines) line.key == key ? change(line) : line,
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
    if (storeId != null) 'storeId': storeId,
  };
}
