import 'package:pos_application/core/utils/epoch_time.dart';
import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/modules/pos/models/line_key.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/migration/sale_rows.dart';
import 'package:pos_application/core/database/migration/sales_migrator.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/sales/models/sale.dart';

import '../../../support/ledger_fixtures.dart';

final RegExp _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);
const String _id1 = '11111111-1111-4111-8111-111111111111';
const String _id2 = '22222222-2222-4222-8222-222222222222';

void main() {
  late AxpertDatabase db;
  late InMemoryLocalStore store;
  final uuid = UuidV4Generator();
  final migrator = SalesMigrator(
    uuid: uuid,
    now: () => DateTime.utc(2026, 10, 12),
  );

  setUp(() {
    db = AxpertDatabase(NativeDatabase.memory());
    store = InMemoryLocalStore();
  });
  tearDown(() => db.close());

  Future<List<SaleEntry>> rows() async => (db.select(
    db.saleEntries,
  )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();

  Future<Map<String, dynamic>> markerJson() async {
    final row = await (db.select(
      db.migrationStateEntries,
    )..where((t) => t.key.equals(salesCopyMarkerKey))).getSingle();
    return jsonDecode(row.value) as Map<String, dynamic>;
  }

  Future<void> writeSales(List<Sale> sales) => store.write(
    StorageKeys.sales,
    <Map<String, dynamic>>[for (final s in sales) s.toJson()],
  );

  Future<List<Sale>> loaded() async => (await SaleRows.read(db)).list;

  test('missing key copies an empty list, LocalStore untouched', () async {
    final outcome = await migrator.ensureCopied(db, store);

    expect(outcome.result, SalesCopyResult.copied);
    expect(await rows(), isEmpty);
    expect(await store.has(StorageKeys.sales), isFalse);
    expect((await markerJson())['count'], 0);
  });

  test('a stored list is copied in order, byte-identical on read', () async {
    final list = [
      ledgerSale('AX000001', saleId: _id1),
      ledgerSale('AX000002', flatDiscount: true, mode: 'Credit'),
      ledgerSale(
        'AX000003',
        saleId: _id2,
        returned: {
          const LineKey(2): const Qty(1000),
          const LineKey(1): const Qty(500),
        },
      ),
    ];
    await writeSales(list);
    final before = await store.read(StorageKeys.sales);

    await migrator.ensureCopied(db, store);

    final r = await rows();
    expect(r.map((e) => e.number), ['AX000001', 'AX000002', 'AX000003']);
    expect(r.map((e) => e.hasSaleId), [true, false, true]);
    expect(r[0].id, _id1);
    expect(_uuidV4.hasMatch(r[1].id), isTrue, reason: 'legacy gets a UUID');
    expect(r[0].createdAt, EpochTime.parse('2026-10-12T00:00:00.000Z'));
    final back = await loaded();
    expect(
      jsonEncode([for (final s in back) s.toJson()]),
      jsonEncode([for (final s in list) s.toJson()]),
    );
    expect(back[1].saleId, isNull, reason: 'legacy ids never reach the JSON');
    expect(back[2].returned.keys.toList(), [
      const LineKey(2),
      const LineKey(1),
    ], reason: 'refund order');
    expect(await store.read(StorageKeys.sales), before);
    final report = (await markerJson())['report'] as Map<String, dynamic>;
    expect(report['legacy_without_sale_id'], 1);
  });

  test('lines keep the full snapshot and the returned quantity', () async {
    await writeSales([
      ledgerSale(
        'AX000001',
        saleId: _id1,
        returned: {const LineKey(2): const Qty(1000)},
      ),
    ]);
    await migrator.ensureCopied(db, store);

    final lines = await (db.select(
      db.saleLineEntries,
    )..orderBy([(t) => OrderingTerm.asc(t.lineNo)])).get();
    expect(lines.map((l) => l.productLegacyId), [1, 2]);
    expect(lines.map((l) => l.productGstBp), [1800, 550]);
    expect(lines.map((l) => l.productFavourite), [true, false]);
    expect(lines.map((l) => l.returnedQtyMilli), [0, 1000]);
    expect(lines.map((l) => l.discountBp), [0, 500]);
  });

  test('a stored [] stays empty', () async {
    await store.write(StorageKeys.sales, <dynamic>[]);

    await migrator.ensureCopied(db, store);

    expect(await rows(), isEmpty);
    expect((await markerJson())['count'], 0);
  });

  test('a stored non-list copies as empty (as Mock load returns [])', () async {
    await store.write(StorageKeys.sales, 'oops');

    await migrator.ensureCopied(db, store);

    expect(await rows(), isEmpty);
  });

  test('second run is a no-op', () async {
    await writeSales([ledgerSale('AX000001', saleId: _id1)]);
    await migrator.ensureCopied(db, store);
    await writeSales([]);

    final again = await migrator.ensureCopied(db, store);

    expect(again.result, SalesCopyResult.alreadyCopied);
    expect(await rows(), hasLength(1));
  });

  for (final bad in <String, Map<String, dynamic> Function(Sale)>{
    'missing number': (s) => s.toJson()..remove('number'),
    'wrong-type date': (s) => s.toJson()..['date'] = 5,
    'missing totals': (s) => s.toJson()..remove('totals'),
    'bad returned': (s) => s.toJson()..['returned'] = 'x',
  }.entries) {
    test('bad record (${bad.key}) throws, nothing written', () async {
      await store.write(StorageKeys.sales, [
        bad.value(ledgerSale('AX000001', saleId: _id1)),
      ]);

      await expectLater(migrator.ensureCopied(db, store), throwsA(anything));

      expect(await rows(), isEmpty);
      expect(await db.select(db.migrationStateEntries).get(), isEmpty);
    });
  }

  test('duplicate numbers are imported and reported', () async {
    await writeSales([
      ledgerSale('AX000001'),
      ledgerSale('AX000001', saleId: _id1),
      ledgerSale('AX000001'),
    ]);

    final outcome = await migrator.ensureCopied(db, store);

    expect(outcome.report!.duplicateNumbers, {'AX000001': 3});
    expect(outcome.report!.hasFindings, isTrue);
    expect(await rows(), hasLength(3));
    expect((await rows()).map((r) => r.id).toSet(), hasLength(3));
    expect(await loaded(), hasLength(3));
  });

  test('duplicate saleIds stop the copy: nothing written', () async {
    await writeSales([
      ledgerSale('AX000001', saleId: _id1),
      ledgerSale('AX000002', saleId: _id1),
    ]);

    await expectLater(
      migrator.ensureCopied(db, store),
      throwsA(isA<DuplicateSaleIdsException>()),
    );

    expect(await rows(), isEmpty);
    expect(await db.select(db.migrationStateEntries).get(), isEmpty);
  });

  test('a returned product that is not a line stops the copy', () async {
    await writeSales([
      ledgerSale(
        'AX000001',
        saleId: _id1,
        returned: {const LineKey(99): const Qty(1000)},
      ),
    ]);

    await expectLater(
      migrator.ensureCopied(db, store),
      throwsA(isA<OrphanReturnedException>()),
    );

    expect(await rows(), isEmpty);
  });

  test('verification failure rolls everything back', () async {
    await writeSales([ledgerSale('AX000001', saleId: _id1)]);
    // A trigger that rewrites the number makes the read-back differ.
    await db.customStatement(
      'CREATE TRIGGER t AFTER INSERT ON sales BEGIN '
      "UPDATE sales SET number = 'ZZ' WHERE id = NEW.id; END",
    );

    await expectLater(migrator.ensureCopied(db, store), throwsA(anything));

    expect(await rows(), isEmpty);
    expect(await db.select(db.saleLineEntries).get(), isEmpty);
    expect(await db.select(db.migrationStateEntries).get(), isEmpty);
  });

  test('stale key re-copies, keeps UUIDs (also legacy), tombstones', () async {
    await writeSales([
      ledgerSale('AX000001'),
      ledgerSale('AX000002', saleId: _id1),
      ledgerSale('AX000003'),
    ]);
    await migrator.ensureCopied(db, store);
    final first = {for (final r in await rows()) r.number: r.id};

    await writeSales([
      ledgerSale('AX000001'),
      ledgerSale('AX000002', saleId: _id1),
      ledgerSale('AX000003', returned: {const LineKey(1): const Qty(1000)}),
      ledgerSale('AX000004', saleId: _id2),
    ]);
    await store.write(StorageKeys.salesDriftStale, true);

    final outcome = await migrator.ensureCopied(db, store);

    expect(outcome.result, SalesCopyResult.recopied);
    final r = await rows();
    expect({for (final e in r) e.number: e.id}, {...first, 'AX000004': _id2});
    expect(await store.has(StorageKeys.salesDriftStale), isFalse);
    expect((await loaded()).map((s) => s.returned.length), [0, 0, 1, 0]);
  });

  test('stale re-copy with a removed sale tombstones, never deletes', () async {
    await writeSales([
      ledgerSale('AX000001', saleId: _id1),
      ledgerSale('AX000002', saleId: _id2),
    ]);
    await migrator.ensureCopied(db, store);
    await writeSales([ledgerSale('AX000001', saleId: _id1)]);
    await store.write(StorageKeys.salesDriftStale, true);

    await migrator.ensureCopied(db, store);

    final r = await rows();
    expect(r, hasLength(2));
    expect(r[1].deletedAt, EpochTime.parse('2026-10-12T00:00:00.000Z'));
    expect((await loaded()).map((s) => s.number), ['AX000001']);
    expect(await db.select(db.saleLineEntries).get(), hasLength(4));
  });

  test('failed re-copy keeps old rows and the stale key', () async {
    await writeSales([ledgerSale('AX000001', saleId: _id1)]);
    await migrator.ensureCopied(db, store);
    await store.write(StorageKeys.sales, [
      {'number': 'broken'},
    ]);
    await store.write(StorageKeys.salesDriftStale, true);

    await expectLater(migrator.ensureCopied(db, store), throwsA(anything));

    expect((await rows()).map((r) => r.number), ['AX000001']);
    expect(await store.has(StorageKeys.salesDriftStale), isTrue);
  });
}
