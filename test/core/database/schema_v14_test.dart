import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/migration/catalog_v14_migration.dart';
import 'package:pos_application/core/database/tables/unit_entries.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' show Database, sqlite3;

final _uuid4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void _product(
  Database raw,
  String id,
  int position,
  String barcode, {
  String? store = 's1',
  int? deleted,
}) {
  raw.execute(
    'INSERT INTO products (id, legacy_id, position, name, code, barcode, '
    "price_minor, category, sub, stock, gst_bp, image, favourite, store_id, "
    "created_at, updated_at, deleted_at) VALUES (?, ?, ?, ?, ?, ?, 100, 'c', "
    "'s', 5, 500, -1, 0, ?, 1, 1, ?)",
    [id, position + 1, position, 'Name $id', 'C$id', barcode, store, deleted],
  );
}

/// A v13 database: the current schema without the v14 tables and columns,
/// with two stores and products that exercise the barcode backfill:
/// p1/p2 share a barcode in s1 (p2 is the duplicate), p3 has the same
/// barcode in s2 (fine, other store), p4 has none, p5 is tombstoned,
/// p6/p7 share a barcode with no store (p7 is the duplicate).
Future<void> _buildV13(File file) async {
  final seed = AxpertDatabase(NativeDatabase(file));
  await seed.customSelect('SELECT 1').get();
  await seed.close();
  final raw = sqlite3.open(file.path);
  raw.execute('PRAGMA foreign_keys = OFF');
  for (final t in const [
    'product_barcodes',
    'product_packagings',
    'brands',
    'units',
  ]) {
    raw.execute('DROP TABLE $t');
  }
  raw.execute('ALTER TABLE products DROP COLUMN base_unit_id');
  raw.execute('ALTER TABLE products DROP COLUMN brand_id');
  for (final c in const [
    'packaging_id',
    'unit_name',
    'quantity_base_milli',
    'base_qty_milli',
  ]) {
    raw.execute('ALTER TABLE sale_lines DROP COLUMN $c');
  }
  raw.execute('PRAGMA user_version = 13');
  raw.execute('PRAGMA foreign_keys = ON');
  raw.execute(
    "INSERT INTO currencies (code, name, symbol, exponent, grouping, "
    "created_at, updated_at) VALUES ('INR', 'Rupee', 'R', 2, 'lakh', 1, 1)",
  );
  for (final s in const ['s1', 's2']) {
    raw.execute(
      'INSERT INTO stores (id, name, currency_code, created_at, updated_at) '
      "VALUES (?, ?, 'INR', 1, 1)",
      [s, s],
    );
  }
  _product(raw, 'p1', 0, 'B1');
  _product(raw, 'p2', 1, 'B1');
  _product(raw, 'p3', 2, 'B1', store: 's2');
  _product(raw, 'p4', 3, '');
  _product(raw, 'p5', 4, 'B5', deleted: 9);
  _product(raw, 'p6', 5, 'B6', store: null);
  _product(raw, 'p7', 6, 'B6', store: null);
  raw.execute(
    'INSERT INTO sales (id, has_sale_id, number, position, occurred_at, '
    'store_name, customer_name, customer_legacy_id, mode, sale_type, '
    'bill_discount_type, bill_discount_bp, bill_discount_minor, '
    'discount_reason, points_redeemed, note, items, qty_milli, value_minor, '
    'subtotal_minor, discount_minor, tax_minor, points_minor, total_minor, '
    'tendered_minor, change_minor, created_at, updated_at, store_id) '
    "VALUES ('sa', 1, 'N1', 0, 1, 'S', 'C', 'c', 'Cash', 'Retail', 'percent', "
    "0, 0, '', 0, '', 1, 1000, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, 's1')",
  );
  raw.execute(
    'INSERT INTO sale_lines (id, sale_id, line_no, product_id, '
    'product_legacy_id, product_name, product_code, product_barcode, '
    'product_price_minor, product_category, product_sub, product_stock, '
    'product_gst_bp, product_image, product_favourite, price_minor, qty_milli, '
    "discount_bp, created_at) VALUES ('l1', 'sa', 0, 'p1', 1, 'n', 'c', 'B1', "
    "100, 'c', 's', 5, 500, -1, 0, 100, 1000, 0, 1)",
  );
  raw.close();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('v14_');
    file = File('${dir.path}/db.sqlite');
  });
  tearDown(() => dir.delete(recursive: true));

  test('a fresh database has the eight units and the v14 tables', () async {
    final db = AxpertDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, greaterThanOrEqualTo(14));
    final units = await db.select(db.unitEntries).get();
    expect(
      {for (final u in units) u.code},
      {'piece', 'pack', 'carton', 'box', 'kg', 'g', 'litre', 'ml'},
    );
    expect(units.firstWhere((u) => u.code == 'kg').kind, 'weight');
    expect(units.firstWhere((u) => u.code == 'ml').kind, 'volume');
    expect(units.firstWhere((u) => u.code == 'box').kind, 'count');
    expect(await db.select(db.brandEntries).get(), isEmpty);
    expect(await db.select(db.packagingEntries).get(), isEmpty);
    expect(await db.select(db.barcodeEntries).get(), isEmpty);
  });

  test(
    'v13 upgrades: units, base unit, barcodes and the duplicate list',
    () async {
      await _buildV13(file);
      final db = AxpertDatabase(NativeDatabase(file));
      addTearDown(db.close);

      final v = await db.customSelect('PRAGMA user_version').getSingle();
      expect(v.read<int>('user_version'), db.schemaVersion);

      final units = await db.select(db.unitEntries).get();
      expect(units, hasLength(8));
      expect(
        units.map((u) => u.id).toSet(),
        SeedUnits.all.map((u) => u.id).toSet(),
      );

      // Every product (also the tombstoned one) reads piece; no brand.
      final products = await db.select(db.productEntries).get();
      expect(products, hasLength(7));
      expect(products.every((p) => p.baseUnitId == SeedUnits.piece.id), isTrue);
      expect(products.every((p) => p.brandId == null), isTrue);
      expect(
        products.every((p) => p.barcode.isNotEmpty || p.id == 'p4'),
        isTrue,
      );

      // Live, non-empty, first per (store, barcode): p1, p3, p6.
      final barcodes = await db.select(db.barcodeEntries).get();
      expect(barcodes, hasLength(3));
      expect({for (final b in barcodes) b.productId}, {'p1', 'p3', 'p6'});
      expect(barcodes.every((b) => b.packagingId == null), isTrue);
      expect(barcodes.every((b) => _uuid4.hasMatch(b.id)), isTrue);
      final byProduct = {for (final b in barcodes) b.productId: b};
      expect(byProduct['p1']!.storeId, 's1');
      expect(byProduct['p3']!.storeId, 's2');
      expect(byProduct['p6']!.storeId, isNull);
      expect(byProduct['p6']!.barcode, 'B6');

      // The old column keeps every value.
      expect({
        for (final p in products) p.id: p.barcode,
      }, containsPair('p2', 'B1'));

      // The exact duplicate list: barcode, kept product, skipped products.
      final state =
          await (db.select(db.migrationStateEntries)
                ..where((t) => t.key.equals(CatalogV14Migration.duplicatesKey)))
              .getSingle();
      final report = (jsonDecode(state.value) as List)
          .cast<Map<String, dynamic>>();
      expect(report, hasLength(2));
      final s1 = report.firstWhere((r) => r['store_id'] == 's1');
      expect(s1['barcode'], 'B1');
      expect((s1['kept'] as Map)['id'], 'p1');
      expect(((s1['skipped'] as List).single as Map)['id'], 'p2');
      final none = report.firstWhere((r) => r['store_id'] == null);
      expect(none['barcode'], 'B6');
      expect((none['kept'] as Map)['id'], 'p6');
      expect(((none['skipped'] as List).single as Map)['id'], 'p7');

      // Existing rows survive, new snapshot columns are null.
      final lines = await db.select(db.saleLineEntries).get();
      expect(lines, hasLength(1));
      expect(lines.single.packagingId, isNull);
      expect(lines.single.unitName, isNull);
      expect(lines.single.quantityBaseMilli, isNull);
      expect(lines.single.baseQtyMilli, isNull);
      expect(lines.single.qtyMilli, 1000);

      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    },
  );

  test('a database without duplicates writes no duplicate record', () async {
    final db = AxpertDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(await db.select(db.migrationStateEntries).get(), isEmpty);
  });

  test('constraints: quantity, kind, unique packaging and barcode', () async {
    final db = AxpertDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(
      "INSERT INTO currencies (code, name, symbol, exponent, grouping, "
      "created_at, updated_at) VALUES ('INR', 'R', 'R', 2, 'lakh', 1, 1)",
    );
    for (final s in const ['s1', 's2']) {
      await db.customStatement(
        'INSERT INTO stores (id, name, currency_code, created_at, updated_at) '
        "VALUES ('$s', 'S', 'INR', 1, 1)",
      );
    }
    for (final (i, p) in const ['p1', 'p2'].indexed) {
      await db.customStatement(
        'INSERT INTO products (id, legacy_id, position, name, code, barcode, '
        'price_minor, category, sub, stock, gst_bp, image, favourite, '
        "store_id, created_at, updated_at) VALUES ('$p', ${i + 1}, $i, 'n', "
        "'c', '', 100, 'c', 's', 0, 0, -1, 0, 's1', 1, 1)",
      );
    }
    Future<void> pack(String id, String unit, int qty, {int? deleted}) =>
        db.customStatement(
          'INSERT INTO product_packagings (id, product_id, unit_id, name, '
          'quantity_base_milli, created_at, updated_at, deleted_at) VALUES '
          "('$id', 'p1', '$unit', 'n', $qty, 1, 1, ${deleted ?? 'NULL'})",
        );
    await pack('k1', SeedUnits.carton.id, 24000);
    await expectLater(pack('k2', SeedUnits.pack.id, 0), throwsA(anything));
    await expectLater(pack('k3', SeedUnits.pack.id, -5), throwsA(anything));
    await expectLater(pack('k4', SeedUnits.carton.id, 6000), throwsA(anything));
    await pack('k5', SeedUnits.pack.id, 6000);
    // A tombstoned level frees the pair again (partial unique index).
    await db.customStatement(
      'UPDATE product_packagings SET deleted_at = 5 WHERE id = \'k1\'',
    );
    await pack('k6', SeedUnits.carton.id, 12000);

    Future<void> code(
      String id,
      String? store,
      String barcode, {
      int? deleted,
    }) => db.customStatement(
      'INSERT INTO product_barcodes (id, product_id, store_id, barcode, '
      'created_at, updated_at, deleted_at) VALUES ($id, \'p1\', '
      "${store == null ? 'NULL' : "'$store'"}, '$barcode', 1, 1, "
      "${deleted ?? 'NULL'})",
    );
    await code("'b1'", 's1', 'X1');
    await expectLater(code("'b2'", 's1', 'X1'), throwsA(anything));
    await code("'b3'", 's2', 'X1'); // another store
    await code("'b4'", null, 'X1'); // the shared (null) scope
    await expectLater(code("'b5'", null, 'X1'), throwsA(anything));
    await code("'b6'", 's1', 'X1', deleted: 3); // tombstoned rows never clash

    await expectLater(
      db.customStatement(
        'INSERT INTO units (id, code, name, kind, created_at, updated_at) '
        "VALUES ('u', 'dozen', 'Dozen', 'length', 1, 1)",
      ),
      throwsA(anything),
    );
    await expectLater(
      db.customStatement(
        'INSERT INTO product_packagings (id, product_id, unit_id, name, '
        'quantity_base_milli, created_at, updated_at) '
        "VALUES ('z', 'p2', 'missing', 'n', 1000, 1, 1)",
      ),
      throwsA(anything),
    );
  });

  test('a failed v14 step rolls back and leaves v13 intact', () async {
    await _buildV13(file);
    final seed = sqlite3.open(file.path);
    // A leftover table of the wrong shape under the new name: its creation is
    // skipped and the unit seeding fails after the columns were added.
    seed.execute('CREATE TABLE units (x INTEGER)');
    seed.close();

    final db = AxpertDatabase(NativeDatabase(file));
    await expectLater(
      db.customSelect('SELECT 1').getSingle(),
      throwsA(anything),
    );
    try {
      await db.close();
    } on Object {
      // The migration failed on purpose.
    }

    final raw = sqlite3.open(file.path);
    addTearDown(raw.close);
    expect(raw.select('PRAGMA user_version').single['user_version'], 13);
    final cols = {
      for (final r in raw.select('PRAGMA table_info(products)'))
        r['name'] as String,
    };
    expect(cols, isNot(contains('base_unit_id')));
    expect(cols, isNot(contains('brand_id')));
    final lineCols = {
      for (final r in raw.select('PRAGMA table_info(sale_lines)'))
        r['name'] as String,
    };
    expect(lineCols, isNot(contains('packaging_id')));
    for (final t in const [
      'brands',
      'product_packagings',
      'product_barcodes',
    ]) {
      expect(
        raw.select("SELECT 1 FROM sqlite_master WHERE name = '$t'"),
        isEmpty,
      );
    }
    expect(raw.select('SELECT count(*) AS n FROM products').single['n'], 7);
    expect(raw.select('SELECT count(*) AS n FROM sale_lines').single['n'], 1);
    expect(raw.select('PRAGMA table_info(units)').map((r) => r['name']), ['x']);
  });
}
