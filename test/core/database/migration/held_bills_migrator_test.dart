import 'package:pos_application/core/utils/epoch_time.dart';
import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/migration/held_bill_rows.dart';
import 'package:pos_application/core/database/migration/held_bills_migrator.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/pos/models/held_bill.dart';

import '../../../support/held_fixtures.dart';

final RegExp _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  late AxpertDatabase db;
  late InMemoryLocalStore store;
  final uuid = UuidV4Generator();
  final migrator = HeldBillsMigrator(
    uuid: uuid,
    now: () => DateTime.utc(2026, 10, 12),
  );

  setUp(() {
    db = AxpertDatabase(NativeDatabase.memory());
    store = InMemoryLocalStore();
  });
  tearDown(() => db.close());

  Future<List<HeldBillEntry>> rows() async => (db.select(
    db.heldBillEntries,
  )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();

  Future<Map<String, dynamic>> markerJson() async {
    final row = await (db.select(
      db.migrationStateEntries,
    )..where((t) => t.key.equals(heldCopyMarkerKey))).getSingle();
    return jsonDecode(row.value) as Map<String, dynamic>;
  }

  Future<void> writeBills(List<HeldBill> bills) => store.write(
    StorageKeys.held,
    <Map<String, dynamic>>[for (final b in bills) b.toJson()],
  );

  Future<void> save(List<HeldBill> bills, {int now = 1000}) =>
      db.durableTransaction(
        () => HeldBillRows.apply(db, bills, now: now, uuid: uuid),
      );

  test('missing key copies an empty list, LocalStore untouched', () async {
    final outcome = await migrator.ensureCopied(db, store);

    expect(outcome.result, HeldCopyResult.copied);
    expect(await rows(), isEmpty);
    expect(await store.has(StorageKeys.held), isFalse);
    final marker = await markerJson();
    expect(marker['count'], 0);
    expect(marker['copied_at'], '2026-10-12T00:00:00.000Z');
  });

  test('a stored list is copied in order with snapshot and time', () async {
    await writeBills([heldBill('H2', note: 'n'), heldBill('H1', productId: 3)]);
    final before = await store.read(StorageKeys.held);

    await migrator.ensureCopied(db, store);

    final r = await rows();
    expect(r.map((e) => e.ref), ['H2', 'H1']);
    expect(r.map((e) => e.position), [0, 1]);
    expect(r.every((e) => _uuidV4.hasMatch(e.id)), isTrue);
    expect(r.first.heldAt, EpochTime.parse('2026-10-12T10:00:00.000Z'));
    expect(r.first.createdAt, EpochTime.parse('2026-10-12T00:00:00.000Z'));
    expect(r.first.deletedAt, isNull);
    expect(jsonDecode(r.first.cartJson)['note'], 'n');
    expect(await store.read(StorageKeys.held), before);
    expect((await markerJson())['count'], 2);
    expect((await HeldBillRows.readList(db)).map((b) => b.toJson()), [
      for (final b in [heldBill('H2', note: 'n'), heldBill('H1', productId: 3)])
        b.toJson(),
    ]);
  });

  test('a stored [] copies as empty', () async {
    await store.write(StorageKeys.held, <Object?>[]);
    await migrator.ensureCopied(db, store);
    expect(await rows(), isEmpty);
    expect((await markerJson())['count'], 0);
  });

  test('a stored non-list copies as empty (as Mock load returns [])', () async {
    await store.write(StorageKeys.held, 'oops');
    await migrator.ensureCopied(db, store);
    expect(await rows(), isEmpty);
    expect((await markerJson())['count'], 0);
  });

  test('second run is a no-op; live rows are not re-verified', () async {
    await writeBills([heldBill('H1')]);
    await migrator.ensureCopied(db, store);
    await (db.update(
      db.heldBillEntries,
    )).write(const HeldBillEntriesCompanion(ref: Value('CHANGED')));

    final outcome = await migrator.ensureCopied(db, store);

    expect(outcome.result, HeldCopyResult.alreadyCopied);
    expect((await rows()).single.ref, 'CHANGED');
  });

  for (final bad in <String, Object?>{
    'missing ref': {'time': 't', 'cart': heldBill('H').cart.toJson()},
    'wrong-type time': {...heldBill('H').toJson(), 'time': 5},
    'missing cart': {'ref': 'H', 'time': 't'},
    'cart not a map': {'ref': 'H', 'time': 't', 'cart': 'x'},
    'bad line': {
      ...heldBill('H').toJson(),
      'cart': {
        ...heldBill('H').cart.toJson(),
        'lines': [
          {'qty': 'x'},
        ],
      },
    },
  }.entries) {
    test('bad record (${bad.key}) throws, nothing written', () async {
      await store.write(StorageKeys.held, [heldBill('G').toJson(), bad.value]);

      await expectLater(
        migrator.ensureCopied(db, store),
        throwsA(isA<Error>()),
      );

      expect(await rows(), isEmpty);
      expect(await db.select(db.migrationStateEntries).get(), isEmpty);
    });
  }

  test('verification failure rolls everything back', () async {
    await writeBills([heldBill('H1')]);
    await db.customStatement(
      'CREATE TRIGGER corrupt AFTER INSERT ON held_bills BEGIN '
      "UPDATE held_bills SET held_at = 'x' WHERE id = NEW.id; END",
    );

    await expectLater(migrator.ensureCopied(db, store), throwsA(anything));

    expect(await rows(), isEmpty);
    expect(await db.select(db.migrationStateEntries).get(), isEmpty);
  });

  test('duplicate refs: all imported in order, reported, no rename', () async {
    await writeBills([
      heldBill('H7', productId: 1),
      heldBill('H7', productId: 2),
      heldBill('H8'),
      heldBill('H7', productId: 3),
    ]);
    final before = await store.read(StorageKeys.held);

    final outcome = await migrator.ensureCopied(db, store);

    expect((await rows()).map((e) => e.ref), ['H7', 'H7', 'H8', 'H7']);
    expect(
      (await HeldBillRows.readList(
        db,
      )).map((b) => b.cart.lines.first.product.id),
      [1, 2, 1, 3],
    );
    expect(outcome.report!.duplicateRefs, {'H7': 3});
    expect(outcome.report!.hasFindings, isTrue);
    expect(((await markerJson())['report'] as Map)['duplicate_refs'], {
      'H7': 3,
    });
    expect(await store.read(StorageKeys.held), before);
  });

  test('stale key re-copies, keeps UUIDs, tombstones removed rows', () async {
    await writeBills([heldBill('A'), heldBill('B', productId: 2)]);
    await migrator.ensureCopied(db, store);
    final ids = {for (final r in await rows()) r.ref: r.id};
    await writeBills([
      heldBill('C', productId: 3),
      heldBill('A', qtyMilli: 5000),
    ]);
    await store.write(StorageKeys.heldDriftStale, true);

    final outcome = await migrator.ensureCopied(db, store);

    expect(outcome.result, HeldCopyResult.recopied);
    expect(await store.has(StorageKeys.heldDriftStale), isFalse);
    final all = await db.select(db.heldBillEntries).get();
    final byRef = {for (final r in all) r.ref: r};
    expect(byRef['A']!.id, ids['A']);
    expect(byRef['A']!.position, 1);
    expect(byRef['B']!.id, ids['B']);
    expect(byRef['B']!.deletedAt, isNotNull);
    expect(byRef['C']!.position, 0);
    expect((await HeldBillRows.readList(db)).map((b) => b.ref), ['C', 'A']);
  });

  test('failed re-copy keeps old rows and the stale key', () async {
    await writeBills([heldBill('A')]);
    await migrator.ensureCopied(db, store);
    await store.write(StorageKeys.held, [
      {'ref': 'x'},
    ]);
    await store.write(StorageKeys.heldDriftStale, true);

    await expectLater(
      migrator.ensureCopied(db, store),
      throwsA(isA<TypeError>()),
    );

    expect(await store.has(StorageKeys.heldDriftStale), isTrue);
    expect((await rows()).map((e) => e.ref), ['A']);
  });

  group('HeldBillRows.apply', () {
    test('removing bills tombstones, never deletes; UUIDs stay', () async {
      await save([heldBill('A'), heldBill('B'), heldBill('C')]);
      final ids = {for (final r in await rows()) r.ref: r.id};

      await save([heldBill('B')], now: 2000);
      final all = await db.select(db.heldBillEntries).get();
      expect(all, hasLength(3));
      final byRef = {for (final r in all) r.ref: r};
      expect(byRef['A']!.deletedAt, 2000);
      expect(byRef['C']!.deletedAt, 2000);
      expect(byRef['B']!.deletedAt, isNull);
      expect(byRef['B']!.id, ids['B']);
      expect(byRef['B']!.position, 0);
      expect(byRef['A']!.cartJson, isNotEmpty);
    });

    test('clearing tombstones every active row', () async {
      await save([heldBill('A'), heldBill('B')]);
      await save(<HeldBill>[], now: 2000);
      expect(await HeldBillRows.readList(db), isEmpty);
      expect(
        (await db.select(db.heldBillEntries).get()).every(
          (r) => r.deletedAt == 2000,
        ),
        isTrue,
      );
    });

    test('a ref used again after a tombstone is a NEW row', () async {
      await save([heldBill('A')]);
      final first = (await rows()).single.id;
      await save(<HeldBill>[], now: 2000);
      await save([heldBill('A')], now: 3000);
      final all = await db.select(db.heldBillEntries).get();
      expect(all, hasLength(2));
      final active = all.where((r) => r.deletedAt == null).single;
      expect(active.id, isNot(first));
      expect(active.createdAt, 3000);
    });

    test(
      'k-th duplicate matches the k-th active row; removing one keeps order',
      () async {
        await save([heldBill('D', productId: 1), heldBill('D', productId: 2)]);
        final ids = [for (final r in await rows()) r.id];
        await save([heldBill('D', productId: 1)], now: 2000);
        final active = (await rows())
            .where((r) => r.deletedAt == null)
            .toList();
        expect(active.single.id, ids[0]);
      },
    );

    test('an unchanged list writes nothing (updated_at stays)', () async {
      await save([heldBill('A')]);
      await save([heldBill('A')], now: 2000);
      expect((await rows()).single.updatedAt, 1000);
    });
  });
}
