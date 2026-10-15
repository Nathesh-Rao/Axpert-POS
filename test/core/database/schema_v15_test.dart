import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/database/axpert_database.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' show sqlite3;

/// A v14 database: the current schema without the v15 tables and columns,
/// with one store and one sale.
Future<void> _buildV14(File file, {bool dropSales = false}) async {
  final seed = AxpertDatabase(NativeDatabase(file));
  await seed.customSelect('SELECT 1').get();
  await seed.close();
  final raw = sqlite3.open(file.path);
  raw.execute('PRAGMA foreign_keys = OFF');
  raw.execute('DROP TABLE store_tax_components');
  raw.execute('DROP TABLE store_tax_slabs');
  raw.execute('ALTER TABLE stores DROP COLUMN state_code');
  raw.execute('ALTER TABLE sales DROP COLUMN tax_parts_json');
  raw.execute('PRAGMA user_version = 14');
  raw.execute(
    "INSERT INTO currencies (code, name, symbol, exponent, grouping, "
    "created_at, updated_at) VALUES ('INR', 'Rupee', 'R', 2, 'lakh', 1, 1)",
  );
  raw.execute(
    'INSERT INTO stores (id, name, currency_code, created_at, updated_at) '
    "VALUES ('s1', 'S1', 'INR', 1, 1)",
  );
  raw.execute(
    'INSERT INTO sales (id, has_sale_id, number, position, occurred_at, '
    'store_name, customer_name, customer_legacy_id, mode, sale_type, '
    'bill_discount_type, bill_discount_bp, bill_discount_minor, '
    'discount_reason, points_redeemed, note, items, qty_milli, value_minor, '
    'subtotal_minor, discount_minor, tax_minor, points_minor, total_minor, '
    'tendered_minor, change_minor, created_at, updated_at, store_id) '
    "VALUES ('sa', 1, 'N1', 0, 1, 'S', 'C', 'c', 'Cash', 'Retail', 'percent', "
    "0, 0, '', 0, '', 1, 1000, 1, 1, 0, 7, 0, 1, 1, 0, 1, 1, 's1')",
  );
  if (dropSales) {
    raw.execute('DROP TABLE payments');
    raw.execute('DROP TABLE sale_lines');
    raw.execute('DROP TABLE sales');
  }
  raw.close();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('v15_');
    file = File('${dir.path}/db.sqlite');
  });
  tearDown(() => dir.delete(recursive: true));

  test('v14 upgrades to v15 intact with the new tables and columns', () async {
    await _buildV14(file);
    final db = AxpertDatabase(NativeDatabase(file));
    addTearDown(db.close);

    final v = await db.customSelect('PRAGMA user_version').getSingle();
    expect(v.read<int>('user_version'), 15);
    final store = await db.select(db.storeEntries).getSingle();
    expect(store.id, 's1');
    expect(store.stateCode, isNull);
    final sale = await db.select(db.saleEntries).getSingle();
    expect(sale.taxMinor, 7);
    expect(sale.taxPartsJson, isNull);
    expect(await db.select(db.storeTaxSlabEntries).get(), isEmpty);
    expect(await db.select(db.storeTaxComponentEntries).get(), isEmpty);
  });

  test('a failed v15 step rolls back and leaves v14 intact', () async {
    // No sales table: adding sales.tax_parts_json fails after the tables and
    // the stores column were added.
    await _buildV14(file, dropSales: true);
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
    expect(raw.select('PRAGMA user_version').single['user_version'], 14);
    final cols = {
      for (final r in raw.select('PRAGMA table_info(stores)'))
        r['name'] as String,
    };
    expect(cols, isNot(contains('state_code')));
    for (final t in const ['store_tax_slabs', 'store_tax_components']) {
      expect(
        raw.select("SELECT 1 FROM sqlite_master WHERE name = '$t'"),
        isEmpty,
      );
    }
  });

  test('a slab scheme outside standard and inter_state is refused', () async {
    final db = AxpertDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(
      "INSERT INTO currencies (code, name, symbol, exponent, grouping, "
      "created_at, updated_at) VALUES ('INR', 'R', 'R', 2, 'lakh', 1, 1)",
    );
    await db.customStatement(
      'INSERT INTO stores (id, name, currency_code, created_at, updated_at) '
      "VALUES ('s1', 'S1', 'INR', 1, 1)",
    );
    await expectLater(
      db.customStatement(
        'INSERT INTO store_tax_slabs (id, store_id, name, scheme, created_at, '
        "updated_at) VALUES ('a', 's1', 'x', 'bogus', 1, 1)",
      ),
      throwsA(anything),
    );
  });
}
