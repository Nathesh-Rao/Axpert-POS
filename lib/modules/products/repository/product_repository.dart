import '../models/product.dart';

abstract interface class ProductRepository {
  Future<List<Product>> load();

  Future<void> save(List<Product> products);
}
