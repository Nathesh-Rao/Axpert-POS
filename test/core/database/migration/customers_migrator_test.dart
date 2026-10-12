import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/migration/customer_rows.dart';
import 'package:pos_application/core/database/migration/customers_migrator.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/customers/models/customer.dart';

Customer _c(String id, String name, {String member = '', int points = 0}) =>
    Customer(
      id: id,
      name: name,
      phone: '9876543210',
      email: '',
      member: member,
      points: points,
    );

Map<String, dynamic> _json(Customer c) => c.toJson();

final RegExp _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  late AxpertDatabase db;
  late InMemoryLocalStore store;
  final migrator = CustomersMigrator(
    uuid: UuidV4Generator(),
    now: () => DateTime.utc(2026, 10, 12),
  );

  setUp(() {
    db = AxpertDatabase(NativeDatabase.memory());
    store = InMemoryLocalStore();
  });
  tearDown(() => db.close());

  Future<List<CustomerEntry>> rows() async => (db.select(
    db.customerEntries,
  )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();

  Future<Map<String, dynamic>> markerJson() async {
    final row = await (db.select(
      db.migrationStateEntries,
    )..where((t) => t.key.equals(customersCopyMarkerKey))).getSingle();
    return jsonDecode(row.value) as Map<String, dynamic>;
  }

  test(
    'missing key copies the 4 seed customers, LocalStore untouched',
    () async {
      final outcome = await migrator.ensureCopied(db, store);

      expect(outcome.result, CustomersCopyResult.copied);
      final r = await rows();
      expect(r.map((e) => e.legacyId), ['walk', '1', '2', '3']);
      expect(r.map((e) => e.position), [0, 1, 2, 3]);
      expect(r.every((e) => _uuidV4.hasMatch(e.id)), isTrue);
      expect(r.first.createdAt, '2026-10-12T00:00:00.000Z');
      expect(r.first.deletedAt, isNull);
      expect(await store.has(StorageKeys.customers), isFalse);
      final marker = await markerJson();
      expect(marker['count'], 4);
      expect(marker['checksum'], hasLength(8));
      expect(marker['copied_at'], '2026-10-12T00:00:00.000Z');
    },
  );

  test('a stored list is copied in order', () async {
    await store.write(StorageKeys.customers, [
      _json(_c('9', 'Zed', points: 5)),
      _json(_c('4', 'Amy', member: 'MG1', points: -3)),
    ]);
    await migrator.ensureCopied(db, store);
    expect((await rows()).map((e) => [e.legacyId, e.points]), [
      ['9', 5],
      ['4', -3],
    ]);
  });

  test('a stored [] stays empty (not re-seeded)', () async {
    await store.write(StorageKeys.customers, <Object?>[]);

    await migrator.ensureCopied(db, store);

    expect(await rows(), isEmpty);
    expect((await markerJson())['count'], 0);
  });

  test('second run is a no-op; live rows are not re-verified', () async {
    await migrator.ensureCopied(db, store);
    await (db.update(db.customerEntries)..where((t) => t.legacyId.equals('1')))
        .write(const CustomerEntriesCompanion(points: Value(7)));

    final outcome = await migrator.ensureCopied(db, store);

    expect(outcome.result, CustomersCopyResult.alreadyCopied);
    expect((await rows())[1].points, 7);
  });

  for (final bad in <String, Object?>{
    'missing field': {'id': '1', 'name': 'A', 'phone': '', 'email': ''},
    'wrong type': {..._json(_c('1', 'A')), 'points': '5'},
    'double points': {..._json(_c('1', 'A')), 'points': 250.5},
    'null name': {..._json(_c('1', 'A')), 'name': null},
  }.entries) {
    test('bad record (${bad.key}) throws TypeError, nothing written', () async {
      await store.write(StorageKeys.customers, [
        _json(_c('0', 'Good')),
        bad.value,
      ]);

      await expectLater(
        migrator.ensureCopied(db, store),
        throwsA(isA<TypeError>()),
      );

      expect(await rows(), isEmpty);
      expect(await db.select(db.migrationStateEntries).get(), isEmpty);
    });
  }

  test('a stored null (not a list) throws TypeError', () async {
    await store.write(StorageKeys.customers, null);
    await expectLater(
      migrator.ensureCopied(db, store),
      throwsA(isA<TypeError>()),
    );
  });

  test('verification failure rolls everything back', () async {
    await db.customStatement(
      'CREATE TRIGGER corrupt AFTER INSERT ON customers BEGIN '
      "UPDATE customers SET name = 'x' WHERE id = NEW.id; END",
    );

    await expectLater(migrator.ensureCopied(db, store), throwsA(anything));

    expect(await rows(), isEmpty);
    expect(await db.select(db.migrationStateEntries).get(), isEmpty);
  });

  test('duplicate ids are renamed, never dropped; findings reported', () async {
    await store.write(StorageKeys.customers, [
      _json(_c('7', 'Asha', member: 'MG00007')),
      _json(_c('7', 'Bela', member: 'MG00007')),
      _json(_c('7', 'Asha', member: 'MG00009')),
      _json(_c('7~dup3', 'Dev')),
    ]);
    await store.write(StorageKeys.sales, [
      {'customer': 'Asha'},
      {'customer': 'Bela'},
      {'customer': 'Nobody'},
      {'customer': 'Walk-in Customer'},
    ]);
    final before = await store.read(StorageKeys.customers);

    final outcome = await migrator.ensureCopied(db, store);

    expect((await rows()).map((e) => e.legacyId), [
      '7',
      '7~dup2',
      '7~dup4',
      '7~dup3',
    ]);
    expect((await rows()).map((e) => e.name), ['Asha', 'Bela', 'Asha', 'Dev']);
    expect(await store.read(StorageKeys.customers), before);
    final report = outcome.report!;
    expect(report.renamed.map((r) => '${r.from}>${r.to}'), [
      '7>7~dup2',
      '7>7~dup4',
    ]);
    expect(report.duplicateMembers, {
      'MG00007': ['7', '7~dup2'],
    });
    expect(report.salesChecked, 4);
    expect(report.salesNameUnmatched, 2);
    expect(report.salesNameAmbiguous, 1);
    expect(report.hasFindings, isTrue);
    final stored = (await markerJson())['report'] as Map<String, dynamic>;
    expect(stored['sales_name_ambiguous'], 1);
    expect((stored['renamed'] as List), hasLength(2));
    // Sales are only read: unchanged.
    expect(await store.read(StorageKeys.sales), hasLength(4));
  });

  test('normalize is idempotent', () {
    final once = CustomerRows.normalize([_c('1', 'A'), _c('1', 'B')]);
    final twice = CustomerRows.normalize(once.customers);
    expect(twice.renamed, isEmpty);
    expect(twice.customers, once.customers);
  });

  test('stale key re-copies, keeps UUIDs, tombstones removed rows', () async {
    await store.write(StorageKeys.customers, [
      _json(_c('1', 'A')),
      _json(_c('2', 'B')),
    ]);
    await migrator.ensureCopied(db, store);
    final ids = {for (final r in await rows()) r.legacyId: r.id};
    await store.write(StorageKeys.customers, [
      _json(_c('3', 'C')),
      _json(_c('1', 'A2', points: 9)),
    ]);
    await store.write(StorageKeys.customersDriftStale, true);

    final outcome = await migrator.ensureCopied(db, store);

    expect(outcome.result, CustomersCopyResult.recopied);
    expect(await store.has(StorageKeys.customersDriftStale), isFalse);
    final all = await db.select(db.customerEntries).get();
    final byLegacy = {for (final r in all) r.legacyId: r};
    expect(byLegacy['1']!.id, ids['1']);
    expect(byLegacy['1']!.name, 'A2');
    expect(byLegacy['2']!.id, ids['2']);
    expect(byLegacy['2']!.deletedAt, isNotNull);
    expect(byLegacy['3']!.position, 0);
    expect((await CustomerRows.readList(db)).map((c) => c.id), ['3', '1']);
  });

  test('failed re-copy keeps old rows and the stale key', () async {
    await migrator.ensureCopied(db, store);
    await store.write(StorageKeys.customers, [
      {'id': 'x'},
    ]);
    await store.write(StorageKeys.customersDriftStale, true);

    await expectLater(
      migrator.ensureCopied(db, store),
      throwsA(isA<TypeError>()),
    );

    expect(await store.has(StorageKeys.customersDriftStale), isTrue);
    expect((await rows()).map((e) => e.legacyId), ['walk', '1', '2', '3']);
  });
}
