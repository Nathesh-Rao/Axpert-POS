import '../../../core/services/packaging/packaging_ref.dart';
import '../../../core/services/packaging/packaging_service.dart';
import '../../../core/services/pricing/basis_points.dart';
import '../../../core/services/pricing/currency.dart';
import '../../../core/services/pricing/currency_registry.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../features/products/domain/entities/product.dart';

/// One cart line. Keeps a snapshot of the product like the prototype (the
/// reducer clamps quantity to `product.stock` of the snapshot).
class CartLine {
  const CartLine({
    required this.product,
    required this.qty,
    required this.price,
    required this.discount,
    this.offer,
    this.packaging,
  });

  factory CartLine.fromJson(
    Map<String, dynamic> json, {
    Currency currency = CurrencyRegistry.inr,
  }) => CartLine(
    product: Product.fromJson(
      json['product'] as Map<String, dynamic>,
      currency: currency,
    ),
    qty: Qty(json['qtyMilli'] as int),
    price: Money(json['priceMinor'] as int, currency),
    discount: Bp(json['discountBp'] as int),
    offer: json['offer'] == null
        ? null
        : LineOffer.fromJson(json['offer'] as Map<String, dynamic>),
    packaging: json['packaging'] == null
        ? null
        : PackagingRef.fromJson(json['packaging'] as Map<String, dynamic>),
  );

  factory CartLine.of(Product product) => CartLine(
    product: product,
    qty: Qty.units(1),
    price: product.price,
    discount: Bp.zero,
  );

  final Product product;
  final Qty qty;
  final Money price;

  /// Line discount percent in basis points.
  final Bp discount;

  /// The automatic offer behind this line. Only set on the resolved lines of
  /// a sale (and on its gift rows); a live cart line carries none (DEC-134).
  final LineOffer? offer;

  /// The packaging the line is sold in (DEC-151); null = base unit. Then
  /// [qty] counts packages and [price] is the package price.
  final PackagingRef? packaging;

  /// Quantity in base units, what stock moves by (equal to [qty] without a
  /// packaging).
  Qty get baseQty => packaging == null
      ? qty
      : Qty(
          const PackagingService().baseQtyMilli(
            qty.milli,
            packaging!.quantityBaseMilli,
          ),
        );

  CartLine copyWith({Product? product, Qty? qty, Money? price, Bp? discount}) =>
      CartLine(
        product: product ?? this.product,
        qty: qty ?? this.qty,
        price: price ?? this.price,
        discount: discount ?? this.discount,
        offer: offer,
        packaging: packaging,
      );

  /// The line as sold: [offer] applied (its percent becomes the line discount).
  CartLine withOffer(LineOffer offer) => CartLine(
    product: product,
    qty: qty,
    price: price,
    discount: offer.discountBp > 0 ? Bp(offer.discountBp) : discount,
    offer: offer,
    packaging: packaging,
  );

  CartLine inCurrency(Currency currency) => CartLine(
    product: product.inCurrency(currency),
    qty: qty,
    price: Money(price.minor, currency),
    discount: discount,
    offer: offer,
    packaging: packaging,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'product': product.toJson(),
    'qtyMilli': qty.milli,
    'priceMinor': price.minor,
    'discountBp': discount.value,
    if (offer != null) 'offer': offer!.toJson(),
    if (packaging != null) 'packaging': packaging!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is CartLine &&
      other.product == product &&
      other.qty == qty &&
      other.price == price &&
      other.discount == discount &&
      other.offer == offer &&
      other.packaging == packaging;

  @override
  int get hashCode =>
      Object.hash(product, qty, price, discount, offer, packaging);
}

/// An automatic offer as sold on a line (snapshot).
class LineOffer {
  const LineOffer({
    required this.kind,
    required this.name,
    required this.savingMinor,
    this.discountBp = 0,
    this.unitOffMinor,
    this.isGift = false,
  });

  factory LineOffer.fromJson(Map<String, dynamic> json) => LineOffer(
    kind: json['kind'] as String,
    name: json['name'] as String,
    savingMinor: json['savingMinor'] as int,
    discountBp: json['discountBp'] as int? ?? 0,
    unitOffMinor: json['unitOffMinor'] as int?,
    isGift: json['isGift'] as bool? ?? false,
  );

  /// `discount`, `promotion` or `gift_tier`.
  final String kind;
  final String name;
  final int savingMinor;

  /// Percent off applied to the line (0 for a fixed amount or a gift).
  final int discountBp;

  /// Fixed per-unit reduction (fixed-amount discount).
  final int? unitOffMinor;
  final bool isGift;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind,
    'name': name,
    'savingMinor': savingMinor,
    if (discountBp != 0) 'discountBp': discountBp,
    if (unitOffMinor != null) 'unitOffMinor': unitOffMinor,
    if (isGift) 'isGift': true,
  };

  @override
  bool operator ==(Object other) =>
      other is LineOffer &&
      other.kind == kind &&
      other.name == name &&
      other.savingMinor == savingMinor &&
      other.discountBp == discountBp &&
      other.unitOffMinor == unitOffMinor &&
      other.isGift == isGift;

  @override
  int get hashCode =>
      Object.hash(kind, name, savingMinor, discountBp, unitOffMinor, isGift);
}
