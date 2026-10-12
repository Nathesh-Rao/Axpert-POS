import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/database/migration/product_rows.dart';
import 'package:pos_application/core/database/migration/products_migrator.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/features/products/data/repositories/drift_product_repository.dart';
import 'package:pos_application/features/products/domain/entities/product.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/returns/models/refund_request.dart';
import 'package:pos_application/modules/returns/services/refund_service.dart';
import 'package:pos_application/modules/sales/models/sale.dart';

import '../../support/product_fixtures.dart';
import '../../support/sale_fixtures.dart';
import '../../support/test_session.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  AxpertDatabase? db;

  @override
  Future<AxpertDatabase> open() async =>
      db ?? (throw StateError('database unavailable'));

  @override
  Future<void> close() async {}
}

/// Counts the rows written by INSERT and UPDATE statements (batched or not).
class _WriteCounter extends QueryInterceptor {
  int rows = 0;

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) {
    rows += statements.arguments.length;
    return executor.runBatched(statements);
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    rows++;
    return executor.runInsert(statement, args);
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    rows++;
    return executor.runUpdate(statement, args);
  }
}

String _encode(List<Product> list) => jsonEncode(productsJson(list));

void main() {
  late _WriteCounter counter;
  late AxpertDatabase db;
  late InMemoryLocalStore store;
  late StartupDiagnostics diagnostics;

  setUp(() {
    MockDelay.provider = () => Duration.zero;
    counter = _WriteCounter();
    db = AxpertDatabase(NativeDatabase.memory().interceptWith(counter));
    store = legacySeededStore();
    diagnostics = StartupDiagnostics();
  });
  tearDown(() => db.close());

  DriftProductRepository repo(AxpertDatabase? database) =>
      DriftProductRepository(
        provider: _Provider(database),
        store: store,
        diagnostics: diagnostics,
        uuid: UuidV4Generator(),
      );

  Future<List<ProductEntry>> allRows() => db.select(db.productEntries).get();

  Future<void> expectSnapshotMatchesRows(DriftProductRepository r) async {
    final read = await ProductRows.read(db);
    expect(r.snapshot.keys.toSet(), read.known.keys.toSet());
    for (final e in read.known.entries) {
      final s = r.snapshot[e.key]!;
      expect(s.uuid, e.value.uuid);
      expect(s.position, e.value.position);
      expect(s.active, e.value.active);
      expect(s.product, e.value.product);
    }
  }

  test(
    'save writes Drift and dual-writes the same JSON to LocalStore',
    () async {
      final repository = repo(db);
      final list = await repository.load();
      final next = [...list, prod(20, name: 'New', gstBp: 550)];

      await repository.save(next);

      expect(await allRows(), hasLength(21));
      expect(_encode(next), jsonEncode(await store.read(StorageKeys.products)));
      expect(await repo(db).load(), next);
    },
  );

  group('rows written', () {
    test('an unchanged list writes no row; k changes write k rows', () async {
      await store.write(StorageKeys.products, productsJson(prods(500)));
      final repository = repo(db);
      final list = await repository.load();
      counter.rows = 0;

      await repository.save(list);
      expect(counter.rows, 0, reason: 'unchanged list');

      final deltas = {3: 2, 250: 1, 499: 5};
      final sold = [
        for (final p in list)
          if (deltas.containsKey(p.id))
            p.copyWith(stock: p.stock - deltas[p.id]!)
          else
            p,
      ];
      await repository.save(sold);
      expect(counter.rows, 3, reason: 'checkout: 3 changed products');

      counter.rows = 0;
      await repository.save([
        for (final p in sold)
          if (p.id == 7) p.copyWith(favourite: true) else p,
      ]);
      expect(counter.rows, 1, reason: 'favourite toggle');
    });

    test('the products controller writes only the sold products', () async {
      await store.write(StorageKeys.products, productsJson(prods(500)));
      final controller = ProductsController(repo(db));
      await controller.load();
      counter.rows = 0;

      await controller.applyStockDeltas({10: 1, 11: 2});

      expect(counter.rows, 2);
      final rows = await allRows();
      expect(rows.firstWhere((r) => r.legacyId == 10).stock, 9);
      expect(rows.firstWhere((r) => r.legacyId == 11).stock, 8);
    });
  });

  test(
    'overlapping unawaited saves end at the last value (Drift and LocalStore)',
    () async {
      final repository = repo(db);
      final list = await repository.load();
      List<Product> stock(int n) => [
        for (final p in list)
          if (p.id == 1) p.copyWith(stock: n) else p,
      ];

      final a = repository.save(stock(1));
      final b = repository.save(stock(2));
      final c = repository.save(stock(3));
      await Future.wait([a, b, c]);

      expect((await allRows()).firstWhere((r) => r.legacyId == 1).stock, 3);
      final raw = await store.read(StorageKeys.products) as List<dynamic>;
      expect((raw[1] as Map)['stock'], 3);
      await expectSnapshotMatchesRows(repository);
    },
  );

  group('snapshot', () {
    test('is rebuilt from the rows after the first copy', () async {
      final repository = repo(db);

      await repository.load();

      expect(repository.snapshot, hasLength(20));
      await expectSnapshotMatchesRows(repository);
    });

    test('is replaced after a committed save', () async {
      final repository = repo(db);
      final list = await repository.load();

      await repository.save([prod(99), ...list.skip(1)]);

      expect(repository.snapshot[0]!.active, isFalse);
      expect(repository.snapshot[99]!.position, 0);
      await expectSnapshotMatchesRows(repository);
    });

    test(
      'a failed save leaves it unchanged; a restart re-copies and refreshes it',
      () async {
        final repository = repo(db);
        final list = await repository.load();
        final before = repository.snapshot;
        final beforeProducts = {
          for (final e in before.entries) e.key: e.value.product,
        };
        await db.customStatement(
          'CREATE TRIGGER fail_update BEFORE UPDATE ON products '
          "BEGIN SELECT RAISE(ABORT, 'disk full'); END",
        );
        final sold = [
          for (final p in list)
            if (p.id == 4) p.copyWith(stock: 1) else p,
        ];

        await repository.save(sold);

        expect(identical(repository.snapshot, before), isTrue);
        expect({
          for (final e in repository.snapshot.entries) e.key: e.value.product,
        }, beforeProducts);
        expect(
          (await allRows()).firstWhere((r) => r.legacyId == 4).stock,
          isNot(1),
        );
        expect(await store.read(StorageKeys.productsDriftStale), true);
        expect(
          diagnostics.failures.map((f) => f.stage),
          contains('products save'),
        );
        expect(
          _encode(sold),
          jsonEncode(await store.read(StorageKeys.products)),
        );

        await db.customStatement('DROP TRIGGER fail_update');
        final restarted = repo(db);
        final reloaded = await restarted.load();

        expect(reloaded, sold);
        expect(await store.has(StorageKeys.productsDriftStale), isFalse);
        expect((await allRows()).firstWhere((r) => r.legacyId == 4).stock, 1);
        await expectSnapshotMatchesRows(restarted);
      },
    );

    test(
      'overlapping saves after a failure stay in order and keep the stale key',
      () async {
        final repository = repo(db);
        final list = await repository.load();
        await db.customStatement(
          'CREATE TRIGGER fail_update BEFORE UPDATE ON products '
          "BEGIN SELECT RAISE(ABORT, 'disk full'); END",
        );
        List<Product> stock(int n) => [
          for (final p in list)
            if (p.id == 1) p.copyWith(stock: n) else p,
        ];

        final a = repository.save(stock(1));
        final b = repository.save(stock(2));
        final c = repository.save(stock(3));
        await Future.wait([a, b, c]);

        final raw = await store.read(StorageKeys.products) as List<dynamic>;
        expect((raw[1] as Map)['stock'], 3);
        expect(await store.read(StorageKeys.productsDriftStale), true);
      },
    );
  });

  test(
    'a product that leaves the list is tombstoned; returning keeps its UUID',
    () async {
      final repository = repo(db);
      final list = await repository.load();
      final uuid = repository.snapshot[2]!.uuid;

      await repository.save([
        for (final p in list)
          if (p.id != 2) p,
      ]);
      expect(
        (await allRows()).firstWhere((r) => r.legacyId == 2).deletedAt,
        isNotNull,
      );
      expect(await allRows(), hasLength(20), reason: 'never DELETE');

      await repository.save(list);
      final row = (await allRows()).firstWhere((r) => r.legacyId == 2);
      expect(row.id, uuid);
      expect(row.deletedAt, isNull);
      await expectSnapshotMatchesRows(repository);
    },
  );

  test('fallback session marks stale; restart re-copies', () async {
    final seed = repo(db);
    await seed.load();
    final failing = repo(null);

    final loaded = await failing.load();
    await failing.save([...loaded, prod(30, name: 'Fallback')]);

    expect(diagnostics.hasFailures, isTrue);
    expect(await store.read(StorageKeys.productsDriftStale), true);
    expect(await allRows(), hasLength(20));

    final restarted = await repo(db).load();

    expect(restarted.length, 21);
    expect(await store.has(StorageKeys.productsDriftStale), isFalse);
    expect(await allRows(), hasLength(21));
  });

  test('localStore backend session, then switch back to Drift', () async {
    final seed = repo(db);
    final list = await seed.load();
    await seed.save(list);
    final rollback = LocalStoreProductRepository(store);

    final loaded = await rollback.load();
    expect(loaded, list);
    await rollback.save([for (final p in loaded) p.copyWith(stock: 1)]);

    expect(await store.read(StorageKeys.productsDriftStale), true);

    final back = await repo(db).load();

    expect(back.every((p) => p.stock == 1), isTrue);
    expect(await store.has(StorageKeys.productsDriftStale), isFalse);
  });

  test(
    'duplicate integer ids: loud report, nothing written, LocalStore authoritative',
    () async {
      final list = [prod(0), prod(1), prod(1, name: 'Again')];
      await store.write(StorageKeys.products, productsJson(list));
      final repository = repo(db);

      final loaded = await repository.load();
      await repository.save([...loaded, prod(5)]);

      expect(loaded, list);
      expect(
        diagnostics.failures.map((f) => f.stage),
        contains('products duplicate ids'),
      );
      expect(await store.read(StorageKeys.productsDriftStale), true);
      expect(await allRows(), isEmpty);
      expect(
        await db.select(db.migrationStateEntries).get(),
        isEmpty,
        reason: 'no marker',
      );
      final raw = await store.read(StorageKeys.products) as List<dynamic>;
      expect(
        raw,
        hasLength(4),
        reason: 'the fallback session saved to LocalStore',
      );
    },
  );

  test('duplicate codes and barcodes are reported in diagnostics', () async {
    await store.write(
      StorageKeys.products,
      productsJson([
        prod(0, code: 'A', barcode: '1'),
        prod(1, code: 'a', barcode: '1'),
      ]),
    );

    await repo(db).load();

    expect(diagnostics.failures.single.stage, 'products copy report');
  });

  group('sale snapshots and returns after a product changes', () {
    late DriftProductRepository repository;
    late List<Product> list;
    late Sale sale;

    setUp(() async {
      repository = repo(db);
      list = await repository.load();
      final sold = list[2];
      sale = testSale(
        number: 'AX000001',
        at: DateTime.utc(2026, 10, 12),
        cart: Cart(
          lines: [
            CartLine(
              product: sold,
              qty: Qty.units(2),
              price: sold.price,
              discount: Bp.zero,
            ),
          ],
        ),
      );
    });

    test(
      'editing the product leaves the stored sale and refund quote intact',
      () async {
        final saleJson = jsonEncode(sale.toJson());
        final quote = RefundService.quote(sale, {2: Qty.units(1)});

        await repository.save([
          for (final p in list)
            if (p.id == 2) p.copyWith(stock: 0, favourite: true) else p,
        ]);

        expect(jsonEncode(sale.toJson()), saleJson);
        expect(RefundService.quote(sale, {2: Qty.units(1)}), quote);
        final reread = Sale.fromJson(
          jsonDecode(saleJson) as Map<String, dynamic>,
        );
        expect(reread.cart.lines.single.product, list[2]);
        expect(RefundService.check(sale, {2: Qty.units(2)}), RefundCheck.ok);
      },
    );

    test(
      'a tombstoned product: refund and restock do not throw, id comes back to the same row',
      () async {
        final uuid = repository.snapshot[2]!.uuid;
        await repository.save([
          for (final p in list)
            if (p.id != 2) p,
        ]);

        final controller = ProductsController(repo(db));
        await controller.load();
        expect(controller.byId(2), isNull);

        expect(() => controller.restock({2: 1}), returnsNormally);
        expect(controller.products.length, 19);
        final refunded = RefundService.applyReturned(sale, {2: Qty.units(1)});
        expect(refunded.returned[2], Qty.units(1));
        expect(RefundService.quote(sale, {2: Qty.units(1)}), isNotNull);

        await repository.save(list);
        final row = (await allRows()).firstWhere((r) => r.legacyId == 2);
        expect(row.id, uuid);
        expect(row.deletedAt, isNull);
      },
    );
  });

  test('copy marker report is stored as JSON', () async {
    await repo(db).load();

    final row = await (db.select(
      db.migrationStateEntries,
    )..where((t) => t.key.equals(productsCopyMarkerKey))).getSingle();

    expect((jsonDecode(row.value) as Map)['count'], 20);
  });
}
