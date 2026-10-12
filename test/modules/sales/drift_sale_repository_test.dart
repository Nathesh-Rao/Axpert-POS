import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/sales/repository/drift_sale_repository.dart';

import '../../support/ledger_fixtures.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  AxpertDatabase? db;

  @override
  Future<AxpertDatabase> open() async =>
      db ?? (throw StateError('database unavailable'));

  @override
  Future<void> close() async {}
}

const String _id1 = '11111111-1111-4111-8111-111111111111';
const String _id2 = '22222222-2222-4222-8222-222222222222';

void main() {
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

  DriftSaleRepository repo(AxpertDatabase? database) => DriftSaleRepository(
    provider: _Provider(database),
    store: store,
    diagnostics: diagnostics,
    uuid: UuidV4Generator(),
  );

  Future<List<String>> activeNumbers() async =>
      (await (db.select(db.saleEntries)
                ..where((t) => t.deletedAt.isNull())
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get())
          .map((r) => r.number)
          .toList();

  Future<List<String>> storeNumbers() async =>
      ((await store.read(StorageKeys.sales)) as List<dynamic>)
          .map((e) => (e as Map)['number'] as String)
          .toList();

  test('first load of an empty store gives [] and writes a marker', () async {
    expect(await repo(db).load(), isEmpty);
    expect(await db.select(db.migrationStateEntries).get(), hasLength(1));
    expect(await store.has(StorageKeys.sales), isFalse);
  });

  test('save writes Drift and dual-writes the same LocalStore JSON', () async {
    final repository = repo(db);
    await repository.load();
    final next = [
      ledgerSale('AX000001', saleId: _id1),
      ledgerSale('AX000002', saleId: _id2),
    ];

    await repository.save(next);

    expect(await activeNumbers(), ['AX000001', 'AX000002']);
    expect(await store.read(StorageKeys.sales), [
      for (final s in next) s.toJson(),
    ]);
  });

  test('an unchanged save writes no rows (updated_at stays)', () async {
    final repository = repo(db);
    final list = [ledgerSale('AX000001', saleId: _id1)];
    await repository.load();
    await repository.save(list);
    final before = await db.select(db.saleEntries).getSingle();

    await repository.save(list);

    expect(
      (await db.select(db.saleEntries).getSingle()).updatedAt,
      before.updatedAt,
    );
    expect(await db.select(db.saleLineEntries).get(), hasLength(2));
  });

  test('copy findings are recorded in diagnostics', () async {
    await store.write(StorageKeys.sales, [
      ledgerSale('AX000001').toJson(),
      ledgerSale('AX000001', customerName: 'B').toJson(),
    ]);

    await repo(db).load();

    expect(diagnostics.failures.single.stage, 'sales copy report');
  });

  test('overlapping unawaited saves run in call order', () async {
    final repository = repo(db);
    await repository.load();
    final a = ledgerSale('AX000001', saleId: _id1);
    final b = ledgerSale('AX000002', saleId: _id2);

    final x = repository.save([a]);
    final y = repository.save([a, b]);
    final z = repository.save([
      a,
      b.copyWith(returned: {1: const Qty(1000)}),
    ]);
    await Future.wait([x, y, z]);

    expect(await activeNumbers(), ['AX000001', 'AX000002']);
    expect(await storeNumbers(), ['AX000001', 'AX000002']);
    final loaded = await repo(db).load();
    expect(loaded[1].returned, {1: const Qty(1000)});
  });

  test('fallback session marks stale; restart re-copies', () async {
    final seed = repo(db);
    await seed.load();
    await seed.save([ledgerSale('AX000001', saleId: _id1)]);
    final failing = repo(null);

    final loaded = await failing.load();
    await failing.save([...loaded, ledgerSale('AX000002', saleId: _id2)]);

    expect(diagnostics.hasFailures, isTrue);
    expect(await store.read(StorageKeys.salesDriftStale), true);
    expect(await activeNumbers(), ['AX000001']);

    final restarted = await repo(db).load();

    expect(restarted.map((s) => s.number), ['AX000001', 'AX000002']);
    expect(await store.has(StorageKeys.salesDriftStale), isFalse);
    expect(await activeNumbers(), ['AX000001', 'AX000002']);
  });

  test('localStore backend session, then switch back to Drift', () async {
    final seed = repo(db);
    await seed.load();
    await seed.save([ledgerSale('AX000001', saleId: _id1)]);
    final rollback = LocalStoreSaleRepository(store);

    final loaded = await rollback.load();
    expect(loaded.map((s) => s.number), ['AX000001']);
    await rollback.save([...loaded, ledgerSale('AX000002', saleId: _id2)]);

    expect(await store.read(StorageKeys.salesDriftStale), true);
    expect(await activeNumbers(), ['AX000001']);

    final back = await repo(db).load();

    expect(back.map((s) => s.number), ['AX000001', 'AX000002']);
    expect(await store.has(StorageKeys.salesDriftStale), isFalse);
    expect(await activeNumbers(), ['AX000001', 'AX000002']);
  });

  test('failed re-copy keeps LocalStore authoritative, key stays', () async {
    final seed = repo(db);
    await seed.load();
    await seed.save([ledgerSale('AX000001', saleId: _id1)]);
    await store.write(StorageKeys.salesDriftStale, true);
    await store.write(StorageKeys.sales, [
      {'number': 'x'},
    ]);

    await expectLater(repo(db).load(), throwsA(isA<TypeError>()));

    expect(await store.has(StorageKeys.salesDriftStale), isTrue);
    expect(await activeNumbers(), ['AX000001']);
  });

  test('Drift save failure falls back to LocalStore and marks stale', () async {
    final repository = repo(db);
    await repository.load();
    await db.customStatement('DROP TABLE payments');
    await db.customStatement('DROP TABLE sale_lines');

    await repository.save([ledgerSale('AX000001', saleId: _id1)]);

    expect(await storeNumbers(), ['AX000001']);
    expect(await store.read(StorageKeys.salesDriftStale), true);
    expect(diagnostics.hasFailures, isTrue);
    expect(
      await activeNumbers(),
      isEmpty,
      reason: 'the transaction rolled back',
    );
  });

  test('a failed save leaves the snapshot unchanged', () async {
    final repository = repo(db);
    await repository.load();
    await repository.save([ledgerSale('AX000001', saleId: _id1)]);
    final before = Map.of(repository.snapshot);
    await db.customStatement('DROP TABLE sale_lines');

    await repository.save([
      ledgerSale('AX000001', saleId: _id1),
      ledgerSale('AX000002', saleId: _id2),
    ]);

    expect(repository.snapshot.keys, before.keys);
    expect(repository.database, isNull, reason: 'session left Drift');
  });

  test('a stored sale cannot be edited, only returned (documented)', () async {
    final repository = repo(db);
    await repository.load();
    await repository.save([ledgerSale('AX000001', saleId: _id1)]);

    await repository.save([
      ledgerSale('AX000001', saleId: _id1, customerName: 'Changed'),
    ]);

    // Rejected before any write, the session degrades to LocalStore.
    expect(
      (await db.select(db.saleEntries).getSingle()).customerName,
      'Walk-in Customer',
    );
    expect(diagnostics.failures.last.stage, 'sales save');
    expect(await store.read(StorageKeys.salesDriftStale), true);
  });

  test(
    'duplicate saleIds stop the copy: LocalStore stays authoritative',
    () async {
      await store.write(StorageKeys.sales, [
        ledgerSale('AX000001', saleId: _id1).toJson(),
        ledgerSale('AX000002', saleId: _id1).toJson(),
      ]);

      final loaded = await repo(db).load();

      expect(loaded.map((s) => s.number), ['AX000001', 'AX000002']);
      expect(await db.select(db.saleEntries).get(), isEmpty);
      expect(await db.select(db.migrationStateEntries).get(), isEmpty);
      expect(await store.read(StorageKeys.salesDriftStale), true);
      expect(diagnostics.failures.single.stage, 'sales duplicate sale ids');
    },
  );

  test(
    'an orphan returned id stops the copy: LocalStore stays authoritative',
    () async {
      await store.write(StorageKeys.sales, [
        ledgerSale(
          'AX000001',
          saleId: _id1,
          returned: {99: const Qty(1000)},
        ).toJson(),
      ]);

      final loaded = await repo(db).load();

      expect(loaded.single.returned, {99: const Qty(1000)});
      expect(await db.select(db.saleEntries).get(), isEmpty);
      expect(diagnostics.failures.single.stage, 'sales orphan returned');
    },
  );

  test(
    'links are backfilled at load once customers and products exist',
    () async {
      await store.write(StorageKeys.sales, [
        ledgerSale('AX000001', customerId: 'c9').toJson(),
      ]);
      await repo(db).load();
      expect((await db.select(db.saleEntries).getSingle()).customerId, isNull);
      await db.customStatement(
        "INSERT INTO customers VALUES ('cu1', 'c9', 0, 'N', '', '', '', 0, "
        "'x', 'x', NULL, NULL, NULL, NULL)",
      );

      await repo(db).load();

      expect((await db.select(db.saleEntries).getSingle()).customerId, 'cu1');
    },
  );
}
