import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/bindings/initial_binding.dart';
import 'package:pos_application/core/config/app_config.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/features/products/data/repositories/drift_product_repository.dart';
import 'package:pos_application/features/products/data/repositories/mock_product_repository.dart';

import '../../support/product_fixtures.dart';
import '../../support/test_infrastructure.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  final AxpertDatabase db;

  @override
  Future<AxpertDatabase> open() async => db;

  @override
  Future<void> close() async {}
}

void main() {
  setUp(() => MockDelay.provider = () => Duration.zero);

  test(
    'the debug large dataset never touches Drift or the real LocalStore key',
    () async {
      final db = AxpertDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = InMemoryLocalStore();
      final real = productsJson(prods(3));
      await store.write(StorageKeys.products, real);
      final binding = InitialBinding(
        store,
        infrastructure: testInfrastructure(
          databaseProvider: _Provider(db),
          productsBackend: ProductsBackend.drift,
        ),
      );

      final repository = binding.productRepository(largeDataset: true);
      final loaded = await repository.load();
      await repository.save(loaded.take(5).toList());

      expect(repository, isA<MockProductRepository>());
      expect(loaded.length, 10000);
      expect(await store.read(StorageKeys.products), real);
      expect(await store.has(StorageKeys.productsDriftStale), isFalse);
      expect(await db.select(db.productEntries).get(), isEmpty);
      expect(await db.select(db.migrationStateEntries).get(), isEmpty);
    },
  );

  test('the configured backend picks the repository', () {
    final store = InMemoryLocalStore();
    InitialBinding binding(ProductsBackend backend) => InitialBinding(
      store,
      infrastructure: testInfrastructure(productsBackend: backend),
    );

    expect(
      binding(ProductsBackend.drift).productRepository(largeDataset: false),
      isA<DriftProductRepository>(),
    );
    expect(
      binding(
        ProductsBackend.localStore,
      ).productRepository(largeDataset: false),
      isA<LocalStoreProductRepository>(),
    );
    expect(
      binding(ProductsBackend.mock).productRepository(largeDataset: false),
      isA<MockProductRepository>(),
    );
  });
}
