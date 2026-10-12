import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/config/app_config.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/hold_recall_controller.dart';
import 'package:pos_application/modules/pos/controllers/held_bills_controller.dart';
import 'package:pos_application/modules/pos/repository/drift_held_bill_repository.dart';

import '../../support/held_fixtures.dart';
import '../../support/test_app.dart';
import '../../support/test_infrastructure.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  AxpertDatabase? db;

  @override
  Future<AxpertDatabase> open() async =>
      db ?? (throw StateError('database unavailable'));

  @override
  Future<void> close() async {}
}

void main() {
  useTestApp();
  late AxpertDatabase db;
  late InMemoryLocalStore store;
  late StartupDiagnostics diagnostics;

  setUp(() {
    MockDelay.provider = () => Duration.zero;
    db = AxpertDatabase(NativeDatabase.memory());
    store = InMemoryLocalStore();
    diagnostics = StartupDiagnostics();
  });
  tearDown(() => db.close());

  DriftHeldBillRepository repo(AxpertDatabase? database) =>
      DriftHeldBillRepository(
        provider: _Provider(database),
        store: store,
        diagnostics: diagnostics,
        uuid: UuidV4Generator(),
      );

  Future<List<String>> activeRefs() async =>
      (await (db.select(db.heldBillEntries)
                ..where((t) => t.deletedAt.isNull())
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get())
          .map((r) => r.ref)
          .toList();

  Future<List<String>> storeRefs() async =>
      ((await store.read(StorageKeys.held)) as List<dynamic>)
          .map((e) => (e as Map)['ref'] as String)
          .toList();

  test('first load of an empty store gives [] and writes a marker', () async {
    expect(await repo(db).load(), isEmpty);
    expect(await db.select(db.migrationStateEntries).get(), hasLength(1));
    expect(await store.has(StorageKeys.held), isFalse);
  });

  test('save writes Drift and dual-writes LocalStore', () async {
    final repository = repo(db);
    await repository.load();
    final next = [heldBill('H1'), heldBill('H2', productId: 2)];

    await repository.save(next);

    expect(await activeRefs(), ['H1', 'H2']);
    expect(await storeRefs(), ['H1', 'H2']);
    final again = await repo(db).load();
    expect(again.map((b) => b.toJson()), next.map((b) => b.toJson()));
  });

  test('duplicate refs at save are kept and written back unchanged', () async {
    final repository = repo(db);
    await repository.load();

    await repository.save([heldBill('H5'), heldBill('H5', productId: 2)]);

    expect(await activeRefs(), ['H5', 'H5']);
    expect(await storeRefs(), ['H5', 'H5']);
    expect((await repo(db).load()).map((b) => b.cart.lines.first.product.id), [
      1,
      2,
    ]);
  });

  test('copy findings are recorded in diagnostics', () async {
    await store.write(StorageKeys.held, [
      heldBill('H1').toJson(),
      heldBill('H1', productId: 2).toJson(),
    ]);

    await repo(db).load();

    expect(diagnostics.failures.single.stage, 'held copy report');
  });

  test(
    'overlapping unawaited saves run in call order (Drift and LocalStore)',
    () async {
      final repository = repo(db);
      await repository.load();

      final a = repository.save([heldBill('A')]);
      final b = repository.save([heldBill('A'), heldBill('B')]);
      final c = repository.save([heldBill('B')]);
      await Future.wait([a, b, c]);

      expect(await activeRefs(), ['B']);
      expect(await storeRefs(), ['B']);
      expect(await repo(db).load(), hasLength(1));
    },
  );

  test('fallback session marks stale; restart re-copies', () async {
    final seed = repo(db);
    await seed.load();
    await seed.save([heldBill('A')]);
    final failing = repo(null);

    final loaded = await failing.load();
    await failing.save([...loaded, heldBill('B', productId: 2)]);

    expect(diagnostics.hasFailures, isTrue);
    expect(await store.read(StorageKeys.heldDriftStale), true);
    expect(await activeRefs(), ['A']);

    final restarted = await repo(db).load();

    expect(restarted.map((b) => b.ref), ['A', 'B']);
    expect(await store.has(StorageKeys.heldDriftStale), isFalse);
    expect(await activeRefs(), ['A', 'B']);
  });

  test('localStore backend session, then switch back to Drift', () async {
    final seed = repo(db);
    await seed.load();
    await seed.save([heldBill('A')]);
    final rollback = LocalStoreHeldBillRepository(store);

    final loaded = await rollback.load();
    expect(loaded.map((b) => b.ref), ['A']);
    await rollback.save([heldBill('Z', productId: 3)]);

    expect(await store.read(StorageKeys.heldDriftStale), true);
    expect(await activeRefs(), ['A']);

    final back = await repo(db).load();

    expect(back.map((b) => b.ref), ['Z']);
    expect(await store.has(StorageKeys.heldDriftStale), isFalse);
    expect(await activeRefs(), ['Z']);
  });

  test('failed re-copy keeps LocalStore authoritative, key stays', () async {
    final seed = repo(db);
    await seed.load();
    await seed.save([heldBill('A')]);
    await store.write(StorageKeys.heldDriftStale, true);
    await store.write(StorageKeys.held, [
      {'ref': 'x'},
    ]);

    await expectLater(repo(db).load(), throwsA(isA<TypeError>()));

    expect(await store.has(StorageKeys.heldDriftStale), isTrue);
    expect(await activeRefs(), ['A']);
  });

  test('Drift save failure falls back to LocalStore and marks stale', () async {
    final repository = repo(db);
    await repository.load();
    await db.customStatement('DROP TABLE held_bills');

    await repository.save([heldBill('L')]);

    expect(await storeRefs(), ['L']);
    expect(await store.read(StorageKeys.heldDriftStale), true);
    expect(diagnostics.hasFailures, isTrue);
  });

  group('hold and recall with Drift held bills', () {
    Future<void> boot() => bootTestApp(
      store: store,
      infrastructure: testInfrastructure(
        databaseProvider: _Provider(db),
        heldBackend: HeldBackend.drift,
      ),
    );

    Future<void> settle(bool Function() done) async {
      for (var i = 0; i < 100 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    Future<List<HeldBillEntry>> allRows() async => (db.select(
      db.heldBillEntries,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();

    test('hold writes a row, recall tombstones it (never deletes)', () async {
      await boot();
      Get.find<CartActionsController>().add(
        Get.find<ProductsController>().byId(5)!,
      );
      final hold = Get.find<HoldRecallController>();
      final held = Get.find<HeldBillsController>();

      hold.hold();
      expect(held.count, 1); // memory is authoritative at once
      final ref = held.bills.single.ref;
      await settle(() => false);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      var rows = await allRows();
      expect(rows.map((r) => r.ref), [ref]);
      expect(rows.single.deletedAt, isNull);
      expect(rows.single.cartJson, contains('"lines"'));

      hold.recall(held.bills.single);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      rows = await allRows();
      expect(rows, hasLength(1));
      expect(rows.single.deletedAt, isNotNull);
      expect(held.count, 0);
      expect(await store.read(StorageKeys.held), isEmpty);
    });
  });
}
