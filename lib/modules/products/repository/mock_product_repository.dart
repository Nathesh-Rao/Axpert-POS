import '../../../core/constants/storage_keys.dart';
import '../../../core/mock/mock_delay.dart';
import '../../../core/mock/seed_products.dart';
import '../../../core/services/storage/local_store.dart';
import '../../../core/services/storage/local_store_seeder.dart';
import '../models/product.dart';
import 'product_repository.dart';

/// Persists the product list through [LocalStore]; seeds the prototype data
/// (or [seed], e.g. the debug large dataset) on first run. With [forceSeed]
/// the seed always replaces what is stored (debug large dataset only).
class MockProductRepository implements ProductRepository {
  MockProductRepository(
    this._store, {
    List<Product>? seed,
    this.forceSeed = false,
  }) : _seed = seed;

  final LocalStore _store;
  final List<Product>? _seed;
  final bool forceSeed;

  @override
  Future<List<Product>> load() async {
    await MockDelay.wait();
    final seed = _seed ?? SeedProducts.products();
    if (forceSeed) {
      await _store.write(StorageKeys.products, _encode(seed));
      return seed;
    }
    final json = await LocalStoreSeeder.seedIfMissing(
      _store,
      StorageKeys.products,
      _encode(seed),
    );
    return <Product>[
      for (final item in json as List<dynamic>)
        Product.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> save(List<Product> products) async {
    await MockDelay.wait();
    await _store.write(StorageKeys.products, _encode(products));
  }

  static List<Map<String, dynamic>> _encode(List<Product> products) =>
      <Map<String, dynamic>>[for (final p in products) p.toJson()];
}
