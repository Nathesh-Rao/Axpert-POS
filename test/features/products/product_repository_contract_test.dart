import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/core/services/storage/local_store.dart';
import '../../support/seed/seed_products.dart';
import 'package:pos_application/features/products/data/repositories/drift_product_repository.dart';
import 'package:pos_application/features/products/data/repositories/mock_product_repository.dart';
import 'package:pos_application/features/products/domain/entities/product.dart';
import 'package:pos_application/features/products/domain/repositories/product_repository.dart';

import '../../support/product_fixtures.dart';
import '../../support/test_session.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  final AxpertDatabase db;

  @override
  Future<AxpertDatabase> open() async => db;

  @override
  Future<void> close() async {}
}

/// One backend under test: [create] builds a repository over the shared
/// [store] (a new call is a "restart" on the same persisted data).
class _Backend {
  _Backend(this.create, [this.dispose, this.diagnostics]);

  final ProductRepository Function(LocalStore store) create;
  final Future<void> Function()? dispose;
  final StartupDiagnostics? diagnostics;
}

_Backend _mock() => _Backend(MockProductRepository.new);

_Backend _drift() {
  final db = AxpertDatabase(NativeDatabase.memory());
  final diagnostics = StartupDiagnostics();
  return _Backend(
    (store) => DriftProductRepository(
      provider: _Provider(db),
      store: store,
      diagnostics: diagnostics,
      uuid: UuidV4Generator(),
    ),
    db.close,
    diagnostics,
  );
}

List<int> _ids(List<Product> list) => [for (final p in list) p.id];

String _encode(List<Product> list) => jsonEncode(productsJson(list));

void main() {
  setUp(() => MockDelay.provider = () => Duration.zero);

  final backends = <String, _Backend Function()>{
    'Mock': _mock,
    'Drift (in-memory)': _drift,
  };
  for (final entry in backends.entries) {
    final make = entry.value;
    group('ProductRepository contract: ${entry.key}', () {
      late _Backend backend;
      late InMemoryLocalStore store;

      setUp(() {
        backend = make();
        store = legacySeededStore();
      });
      tearDown(() async => backend.dispose?.call());

      test('first load is the 20 seed products, in order', () async {
        final loaded = await backend.create(store).load();

        expect(loaded, SeedProducts.products());
        expect(_ids(loaded), [for (var i = 0; i < 20; i++) i]);
      });

      test('save then load on a new instance round-trips in order', () async {
        final list = [
          prod(2, gstBp: 550, favourite: true),
          prod(0, stock: 0),
          prod(1, image: 5, priceMinor: 12345, gstBp: 1250),
        ];
        final repo = backend.create(store);
        await repo.load();
        await repo.save(list);

        final loaded = await backend.create(store).load();

        expect(_ids(loaded), [2, 0, 1]);
        expect(loaded, list);
      });

      test(
        'the LocalStore JSON after a save is byte-identical to today',
        () async {
          final list = [
            prod(0, gstBp: 1800),
            prod(1, gstBp: 550),
            prod(2, gstBp: 0),
            prod(3, gstBp: 1250, favourite: true),
          ];
          final repo = backend.create(store);
          await repo.load();
          await repo.save(list);

          expect(
            jsonEncode(await store.read(StorageKeys.products)),
            _encode(list),
          );
        },
      );

      test(
        'stock deltas, favourite toggle and an appended product persist',
        () async {
          final repo = backend.create(store);
          var list = await repo.load();
          list = [
            for (final p in list)
              if (p.id == 3) p.copyWith(stock: p.stock - 4) else p,
          ];
          await repo.save(list);
          list = [
            for (final p in list)
              if (p.id == 5) p.copyWith(favourite: !p.favourite) else p,
          ];
          await repo.save(list);
          list = [...list, prod(20, name: 'New product', code: 'NEW001')];
          await repo.save(list);

          final loaded = await backend.create(store).load();

          expect(loaded, list);
          expect(loaded.length, 21);
          expect(loaded.last.name, 'New product');
          expect(
            jsonEncode(await store.read(StorageKeys.products)),
            _encode(list),
          );
        },
      );

      test('a reordered or shortened list reloads exactly as saved', () async {
        final repo = backend.create(store);
        await repo.load();
        await repo.save(prods(5));
        await repo.save([prod(3), prod(1)]);

        expect(_ids(await backend.create(store).load()), [3, 1]);

        await repo.save([prod(1), prod(2), prod(3)]);
        expect(_ids(await backend.create(store).load()), [1, 2, 3]);
      });

      test('duplicate codes and barcodes: all kept in order', () async {
        final list = [
          prod(0, code: 'SAME', barcode: '111'),
          prod(1, code: 'same', barcode: '222'),
          prod(2, code: 'OTHER', barcode: '111'),
        ];
        await store.write(StorageKeys.products, productsJson(list));

        final loaded = await backend.create(store).load();

        expect(loaded, list);
      });

      // Mock keeps duplicate integer ids; the Drift copy stops safely, keeps
      // LocalStore authoritative and loads the same list from it (DEC-128).
      test('duplicate integer ids: the list loads unchanged', () async {
        final list = [prod(0), prod(1), prod(1, name: 'Again')];
        await store.write(StorageKeys.products, productsJson(list));

        final loaded = await backend.create(store).load();

        expect(loaded, list);
        expect(
          jsonEncode(await store.read(StorageKeys.products)),
          _encode(list),
          reason: 'LocalStore is never modified by a load',
        );
      });

      test('a stored [] stays empty (not re-seeded)', () async {
        await store.write(StorageKeys.products, <Object?>[]);

        expect(await backend.create(store).load(), isEmpty);
      });

      test('a stored value that is not a list throws TypeError', () async {
        for (final value in <Object?>[
          null,
          'x',
          5,
          {'a': 1},
        ]) {
          await store.write(StorageKeys.products, value);
          await expectLater(
            backend.create(store).load(),
            throwsA(isA<TypeError>()),
          );
        }
      });

      test('stored values win, unknown extra keys are ignored', () async {
        await store.write(StorageKeys.products, [
          {...prod(0, stock: 7).toJson(), 'extra': 1},
        ]);

        final loaded = await backend.create(store).load();

        expect(loaded, [prod(0, stock: 7)]);
      });

      final good = prod(1).toJson();
      for (final bad in <String, Object?>{
        'missing field': {'id': 1},
        'null name': {...good, 'name': null},
        'wrong-type stock': {...good, 'stock': '5'},
        'double stock': {...good, 'stock': 2.5},
        'wrong-type id': {...good, 'id': '1'},
        'wrong-type favourite': {...good, 'favourite': 1},
        'not a map': 7,
      }.entries) {
        test('bad record (${bad.key}) makes load throw TypeError', () async {
          await store.write(StorageKeys.products, [good, bad.value]);

          await expectLater(
            backend.create(store).load(),
            throwsA(isA<TypeError>()),
          );
        });
      }

      test('a gst stored as a decimal or whole number round-trips', () async {
        await store.write(StorageKeys.products, [
          {...prod(0).toJson(), 'gst': 5.5},
          {...prod(1).toJson(), 'gst': 12},
          {...prod(2).toJson(), 'gst': 0},
        ]);
        final repo = backend.create(store);
        final loaded = await repo.load();
        await repo.save(loaded);

        expect(loaded.map((p) => p.gst.value), [550, 1200, 0]);
        final raw = await store.read(StorageKeys.products) as List<dynamic>;
        expect(raw.map((e) => (e as Map)['gst']), [5.5, 12, 0]);
      });
    });
  }
}
