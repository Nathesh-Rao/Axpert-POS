import '../../../core/services/pricing/basis_points.dart';
import '../../../core/services/pricing/currency.dart';
import '../../../core/services/pricing/currency_registry.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/qty.dart';
import '../../products/models/product.dart';

/// One cart line. Keeps a snapshot of the product like the prototype (the
/// reducer clamps quantity to `product.stock` of the snapshot).
class CartLine {
  const CartLine({
    required this.product,
    required this.qty,
    required this.price,
    required this.discount,
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

  CartLine copyWith({Product? product, Qty? qty, Money? price, Bp? discount}) =>
      CartLine(
        product: product ?? this.product,
        qty: qty ?? this.qty,
        price: price ?? this.price,
        discount: discount ?? this.discount,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'product': product.toJson(),
    'qtyMilli': qty.milli,
    'priceMinor': price.minor,
    'discountBp': discount.value,
  };

  @override
  bool operator ==(Object other) =>
      other is CartLine &&
      other.product == product &&
      other.qty == qty &&
      other.price == price &&
      other.discount == discount;

  @override
  int get hashCode => Object.hash(product, qty, price, discount);
}
