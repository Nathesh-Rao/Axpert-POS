import '../../../core/services/pricing/basis_points.dart';
import '../../../core/services/pricing/currency.dart';
import '../../../core/services/pricing/currency_registry.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../core/utils/gst_json.dart';

/// Catalog product (prototype `Product`). Price is minor units, `gst` is basis
/// points, stock is whole units (the prototype never adjusts it).
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.code,
    required this.barcode,
    required this.price,
    required this.category,
    required this.sub,
    required this.stock,
    required this.gst,
    required this.image,
    required this.favourite,
  });

  factory Product.fromJson(
    Map<String, dynamic> json, {
    Currency currency = CurrencyRegistry.inr,
  }) => Product(
    id: json['id'] as int,
    name: json['name'] as String,
    code: json['code'] as String,
    barcode: json['barcode'] as String,
    price: Money(json['priceMinor'] as int, currency),
    category: json['category'] as String,
    sub: json['sub'] as String,
    stock: json['stock'] as int,
    gst: GstJson.parse(json['gst']),
    image: json['image'] as int,
    favourite: json['favourite'] as bool,
  );

  final int id;
  final String name;
  final String code;
  final String barcode;
  final Money price;
  final String category;
  final String sub;
  final int stock;
  final Bp gst;

  /// Asset number (assets/products/N.png) or -1 for the CSS placeholder.
  final int image;
  final bool favourite;

  Qty get stockQty => Qty.units(stock);

  bool get hasImage => image >= 0;

  Product copyWith({bool? favourite}) => Product(
    id: id,
    name: name,
    code: code,
    barcode: barcode,
    price: price,
    category: category,
    sub: sub,
    stock: stock,
    gst: gst,
    image: image,
    favourite: favourite ?? this.favourite,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'code': code,
    'barcode': barcode,
    'priceMinor': price.minor,
    'category': category,
    'sub': sub,
    'stock': stock,
    'gst': GstJson.toJson(gst),
    'image': image,
    'favourite': favourite,
  };

  @override
  bool operator ==(Object other) =>
      other is Product &&
      other.id == id &&
      other.name == name &&
      other.code == code &&
      other.barcode == barcode &&
      other.price == price &&
      other.category == category &&
      other.sub == sub &&
      other.stock == stock &&
      other.gst == gst &&
      other.image == image &&
      other.favourite == favourite;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    code,
    barcode,
    price,
    category,
    sub,
    stock,
    gst,
    image,
    favourite,
  );
}
