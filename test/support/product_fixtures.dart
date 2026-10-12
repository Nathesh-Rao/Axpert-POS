import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/features/products/domain/entities/product.dart';

Product prod(
  int id, {
  String? name,
  String? code,
  String? barcode,
  int priceMinor = 4000,
  String category = 'Beverages',
  String sub = 'Soft Drinks',
  int stock = 10,
  int gstBp = 1800,
  int image = -1,
  bool favourite = false,
}) => Product(
  id: id,
  name: name ?? 'Item $id',
  code: code ?? 'C$id',
  barcode: barcode ?? '89000$id',
  price: Money(priceMinor, CurrencyRegistry.inr),
  category: category,
  sub: sub,
  stock: stock,
  gst: Bp(gstBp),
  image: image,
  favourite: favourite,
);

List<Product> prods(int count) => [for (var i = 0; i < count; i++) prod(i)];

List<Map<String, dynamic>> productsJson(List<Product> list) => [
  for (final p in list) p.toJson(),
];
