import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/database/axpert_database.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' show Database, sqlite3;

final _uuid4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// A v11 database: the current schema without the v12 objects, holding a
/// store, products with stock (one with 0, one deleted, one without a store).
Future<void> _buildV11(File file) async {
  final seed = AxpertDatabase(NativeDatabase(file));
  await seed.customSelect('SELECT 1').get();
  await seed.close();
  final raw = sqlite3.open(file.path);
  raw.execute('DROP TABLE inventory_transactions');
  raw.execute('DROP TABLE inventory_balance');
  raw.execute('ALTER TABLE stores DROP COLUMN allow_negative_stock');
  raw.execute('PRAGMA user_version = 11');
  raw.execute(
    "INSERT INTO currencies (code, name, symbol, exponent, grouping, "
    "created_at, updated_at) VALUES ('INR', 'Rupee', 'R', 2, 'lakh', 1, 1)",
  );
  raw.execute(
    "INSERT INTO stores (id, name, currency_code, created_at, updated_at) "
    "VALUES ('s1', 'Shop', 'INR', 1, 1)",
  );
  void product(String id, int legacy, int stock, String? store, int? deleted) {
    raw.execute(
      'INSERT INTO products (id, legacy_id, position, name, code, barcode, '
      'price_minor, category, sub, stock, gst_bp, image, favourite, '
      'created_at, updated_at, store_id, deleted_at) '
      "VALUES (?, ?, 0, 'n', 'c', 'b', 100, 'c', 's', ?, 0, -1, 0, 1, 1, ?, ?)",
      [id, legacy, stock, store, deleted],
    );
  }

  product('p1', 1, 5, 's1', null);
  product('p2', 2, 0, 's1', null);
  product('p3', 3, 9, 's1', 1);
  product('p4', 4, 7, null, null);
  raw.close();
}

int _n(Database raw, String sql) => raw.select(sql).single['n'] as int;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('v12_');
    file = File('${dir.path}/db.sqlite');
  });
  tearDown(() => dir.delete(recursive: true));

  test(
    'a fresh database has the inventory tables and the store flag',
    () async {
      final db = AxpertDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, greaterThanOrEqualTo(12));
      expect(await db.select(db.inventoryBalanceEntries).get(), isEmpty);
      expect(await db.select(db.inventoryTransactionEntries).get(), isEmpty);
      final info = await db.customSelect('PRAGMA table_info(stores)').get();
      expect(
        info.map((r) => r.read<String>('name')),
        contains('allow_negative_stock'),
      );
    },
  );

  test('v11 upgrades: balances and opening rows from products.stock', () async {
    await _buildV11(file);
    final db = AxpertDatabase(NativeDatabase(file));
    addTearDown(db.close);

    final v = await db.customSelect('PRAGMA user_version').getSingle();
    expect(v.read<int>('user_version'), db.schemaVersion);

    final balances = {
      for (final b in await db.select(db.inventoryBalanceEntries).get())
        b.productId: b.quantityMilli,
    };
    // Store products that are not deleted: p1 and p2 (p3 deleted, p4 no store).
    expect(balances, {'p1': 5000, 'p2': 0});

    final txs = await db.select(db.inventoryTransactionEntries).get();
    expect(txs, hasLength(1)); // stock 0 gets a balance row, no transaction
    final t = txs.single;
    expect(
      (t.productId, t.quantityDeltaMilli, t.reason, t.storeId),
      ('p1', 5000, 'opening', 's1'),
    );
    expect(_uuid4.hasMatch(t.id), isTrue);
    expect(t.createdAt, greaterThan(1700000000000));

    final store = await db.select(db.storeEntries).getSingle();
    expect(store.allowNegativeStock, isFalse);
    expect(await db.select(db.productEntries).get(), hasLength(4));
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });

  test('the reason is restricted to the seven values', () async {
    final db = AxpertDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(
      "INSERT INTO currencies (code, name, symbol, exponent, grouping, "
      "created_at, updated_at) VALUES ('INR', 'R', 'R', 2, 'lakh', 1, 1)",
    );
    await db.customStatement(
      "INSERT INTO stores (id, name, currency_code, created_at, updated_at) "
      "VALUES ('s1', 'S', 'INR', 1, 1)",
    );
    await db.customStatement(
      'INSERT INTO products (id, legacy_id, position, name, code, barcode, '
      'price_minor, category, sub, stock, gst_bp, image, favourite, '
      "created_at, updated_at) VALUES ('p1', 1, 0, 'n', 'c', 'b', 1, 'c', 's', "
      '1, 0, -1, 0, 1, 1)',
    );
    Future<void> insert(String reason) => db.customStatement(
      'INSERT INTO inventory_transactions (id, store_id, product_id, '
      "quantity_delta_milli, reason, created_at) VALUES ('$reason', 's1', "
      "'p1', 1, '$reason', 1)",
    );
    for (final r in [
      'sale',
      'return',
      'purchase',
      'adjustment',
      'damage',
      'transfer',
      'opening',
    ]) {
      await insert(r);
    }
    await expectLater(insert('refund'), throwsA(anything));
  });

  test('a failed v12 step rolls back and leaves v11 intact', () async {
    await _buildV11(file);
    final seed = sqlite3.open(file.path);
    // A leftover table of the wrong shape under the new name: the step skips
    // its creation and fails in the backfill, after the other table, the
    // indexes and the store column were created.
    seed.execute('CREATE TABLE inventory_balance (x INTEGER)');
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
    expect(raw.select('PRAGMA user_version').single['user_version'], 11);
    final names = {
      for (final r in raw.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ))
        r['name'] as String,
    };
    expect(names, contains('inventory_balance')); // the leftover, untouched
    expect(names, isNot(contains('inventory_transactions')));
    expect(
      raw.select('PRAGMA table_info(inventory_balance)').map((r) => r['name']),
      ['x'],
    );
    final cols = {
      for (final r in raw.select('PRAGMA table_info(stores)'))
        r['name'] as String,
    };
    expect(cols, isNot(contains('allow_negative_stock')));
    expect(_n(raw, 'SELECT count(*) AS n FROM products'), 4);
  });
}
