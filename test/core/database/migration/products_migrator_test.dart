import 'package:pos_application/core/utils/epoch_time.dart';
import 'dart:convert';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/migration/product_rows.dart';
import 'package:pos_application/core/database/migration/products_migrator.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';

import '../../../support/product_fixtures.dart';
import '../../../support/test_session.dart';

final RegExp _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  late AxpertDatabase db;
  late InMemoryLocalStore store;
  final migrator = ProductsMigrator(
    uuid: UuidV4Generator(),
    now: () => DateTime.utc(2026, 10, 12),
  );

  setUp(() {
    db = AxpertDatabase(NativeDatabase.memory());
    store = legacySeededStore();
  });
  tearDown(() => db.close());

  Future<List<ProductEntry>> rows() async => (db.select(
    db.productEntries,
  )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();

  Future<Map<String, dynamic>> markerJson() async {
    final row = await (db.select(
      db.migrationStateEntries,
    )..where((t) => t.key.equals(productsCopyMarkerKey))).getSingle();
    return jsonDecode(row.value) as Map<String, dynamic>;
  }

  test(
    'missing key copies an empty catalog (no demo data), LocalStore untouched',
    () async {
      final empty = InMemoryLocalStore();
      final outcome = await migrator.ensureCopied(db, empty);

      expect(outcome.result, ProductsCopyResult.copied);
      final list = (await ProductRows.read(db)).list;
      expect(list, isEmpty);
      expect(await empty.has(StorageKeys.products), isFalse);
      expect((await markerJson())['count'], 0);
    },
  );

  test('a stored list is copied in order with UUID v4, gst as bp', () async {
    final list = [
      prod(0, gstBp: 550),
      prod(1, favourite: true, stock: 3),
      prod(2, image: 4),
    ];
    await store.write(StorageKeys.products, productsJson(list));

    await migrator.ensureCopied(db, store);

    final all = await rows();
    expect(all.map((r) => r.legacyId), [0, 1, 2]);
    expect(all.map((r) => r.position), [0, 1, 2]);
    expect(all.every((r) => _uuidV4.hasMatch(r.id)), isTrue);
    expect(all.first.gstBp, 550);
    expect(all.first.currencyCode, 'INR');
    expect(all.first.createdAt, EpochTime.parse('2026-10-12T00:00:00.000Z'));
    expect((await ProductRows.read(db)).list, list);
    expect(
      jsonEncode(await store.read(StorageKeys.products)),
      jsonEncode(productsJson(list)),
    );
    final marker = await markerJson();
    expect(marker['count'], 3);
    expect(marker['checksum'], ProductRows.checksum(list));
  });

  test('a stored [] stays empty (not re-seeded)', () async {
    await store.write(StorageKeys.products, <dynamic>[]);

    await migrator.ensureCopied(db, store);

    expect(await rows(), isEmpty);
    expect((await markerJson())['count'], 0);
  });

  test('second run is a no-op; live rows are not re-verified', () async {
    await store.write(StorageKeys.products, productsJson(prods(3)));
    await migrator.ensureCopied(db, store);
    await db.customStatement("UPDATE products SET name = 'edited'");

    final outcome = await migrator.ensureCopied(db, store);

    expect(outcome.result, ProductsCopyResult.alreadyCopied);
    expect((await rows()).first.name, 'edited');
  });

  for (final bad in <String, Object?>{
    'missing field': {'id': 1},
    'wrong type': {...prod(1).toJson(), 'stock': '5'},
    'double stock': {...prod(1).toJson(), 'stock': 2.5},
    'null name': {...prod(1).toJson(), 'name': null},
    'not a map': 7,
  }.entries) {
    test('bad record (${bad.key}) throws TypeError, nothing written', () async {
      await store.write(StorageKeys.products, [bad.value]);

      await expectLater(
        migrator.ensureCopied(db, store),
        throwsA(isA<TypeError>()),
      );

      expect(await rows(), isEmpty);
      expect(
        await db.select(db.migrationStateEntries).get(),
        isEmpty,
        reason: 'no marker',
      );
    });
  }

  test('a stored null (not a list) throws TypeError', () async {
    await store.write(StorageKeys.products, null);

    await expectLater(
      migrator.ensureCopied(db, store),
      throwsA(isA<TypeError>()),
    );
  });

  test(
    'duplicate integer ids stop the copy: nothing written, no marker',
    () async {
      final list = [prod(0), prod(1), prod(1, name: 'Again')];
      await store.write(StorageKeys.products, productsJson(list));

      await expectLater(
        migrator.ensureCopied(db, store),
        throwsA(
          isA<DuplicateProductIdsException>().having(
            (e) => e.counts,
            'counts',
            {1: 2},
          ),
        ),
      );

      expect(await rows(), isEmpty);
      expect(await db.select(db.migrationStateEntries).get(), isEmpty);
      expect(
        jsonEncode(await store.read(StorageKeys.products)),
        jsonEncode(productsJson(list)),
        reason: 'LocalStore is never modified',
      );
    },
  );

  test('duplicate codes and barcodes are imported and reported', () async {
    final list = [
      prod(0, code: 'ABC', barcode: '111'),
      prod(1, code: 'abc', barcode: '222'),
      prod(2, code: 'X', barcode: '111'),
    ];
    await store.write(StorageKeys.products, productsJson(list));

    final outcome = await migrator.ensureCopied(db, store);

    expect(outcome.report!.hasFindings, isTrue);
    expect(await rows(), hasLength(3));
    final report = (await markerJson())['report'] as Map<String, dynamic>;
    expect(report['duplicate_codes'], {
      'abc': [0, 1],
    });
    expect(report['duplicate_barcodes'], {
      '111': [0, 2],
    });
  });

  test('stale key re-copies, keeps UUIDs, tombstones removed rows', () async {
    await store.write(StorageKeys.products, productsJson(prods(3)));
    await migrator.ensureCopied(db, store);
    final ids = {for (final r in await rows()) r.legacyId: r.id};
    await store.write(
      StorageKeys.products,
      productsJson([prod(2, stock: 99), prod(0), prod(7)]),
    );
    await store.write(StorageKeys.productsDriftStale, true);

    final outcome = await migrator.ensureCopied(db, store);

    expect(outcome.result, ProductsCopyResult.recopied);
    expect(await store.has(StorageKeys.productsDriftStale), isFalse);
    final byLegacy = {
      for (final r in await db.select(db.productEntries).get()) r.legacyId: r,
    };
    expect(byLegacy[0]!.id, ids[0]);
    expect(byLegacy[2]!.id, ids[2]);
    expect(byLegacy[2]!.stock, 99);
    expect(byLegacy[2]!.position, 0);
    expect(byLegacy[1]!.id, ids[1]);
    expect(byLegacy[1]!.deletedAt, isNotNull, reason: 'tombstone, not DELETE');
    expect(byLegacy[7]!.position, 2);
    expect((await ProductRows.read(db)).list.map((p) => p.id), [2, 0, 7]);
  });

  test('failed re-copy keeps old rows and the stale key', () async {
    await store.write(StorageKeys.products, productsJson(prods(2)));
    await migrator.ensureCopied(db, store);
    await store.write(StorageKeys.products, [
      {'id': 'x'},
    ]);
    await store.write(StorageKeys.productsDriftStale, true);

    await expectLater(
      migrator.ensureCopied(db, store),
      throwsA(isA<TypeError>()),
    );

    expect(await store.has(StorageKeys.productsDriftStale), isTrue);
    expect((await ProductRows.read(db)).list.map((p) => p.id), [0, 1]);
  });
}
