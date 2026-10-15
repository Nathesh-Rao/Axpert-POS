import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/database/axpert_database.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' show sqlite3;

final _uuid4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// A v12 database: the current schema without payment_methods and
/// payments.method_id, with two live stores, one tombstoned store and three
/// payments (cash of s1, card of s1, one of a sale without a store).
Future<void> _buildV12(File file) async {
  final seed = AxpertDatabase(NativeDatabase(file));
  await seed.customSelect('SELECT 1').get();
  await seed.close();
  final raw = sqlite3.open(file.path);
  raw.execute('PRAGMA foreign_keys = OFF');
  raw.execute('DROP TABLE payments');
  raw.execute('DROP TABLE payment_methods');
  raw.execute(
    'CREATE TABLE payments (id TEXT NOT NULL, sale_id TEXT NOT NULL '
    'REFERENCES sales (id), method TEXT NOT NULL, amount_minor INTEGER NOT NULL, '
    "currency_code TEXT NOT NULL DEFAULT 'INR', status TEXT NOT NULL, "
    'occurred_at INTEGER NOT NULL, created_at INTEGER NOT NULL, '
    'PRIMARY KEY (id))',
  );
  raw.execute('PRAGMA user_version = 12');
  raw.execute('PRAGMA foreign_keys = ON');
  raw.execute(
    "INSERT INTO currencies (code, name, symbol, exponent, grouping, "
    "created_at, updated_at) VALUES ('INR', 'Rupee', 'R', 2, 'lakh', 1, 1)",
  );
  for (final (id, deleted) in [('s1', null), ('s2', null), ('s3', 5)]) {
    raw.execute(
      'INSERT INTO stores (id, name, currency_code, created_at, updated_at, '
      'deleted_at) VALUES (?, ?, ?, 1, 1, ?)',
      [id, id, 'INR', deleted],
    );
  }
  void sale(String id, String? store) {
    raw.execute(
      'INSERT INTO sales (id, has_sale_id, number, position, occurred_at, '
      'store_name, customer_name, customer_legacy_id, mode, sale_type, '
      'bill_discount_type, bill_discount_bp, bill_discount_minor, '
      'discount_reason, points_redeemed, note, items, qty_milli, value_minor, '
      'subtotal_minor, discount_minor, tax_minor, points_minor, total_minor, '
      'tendered_minor, change_minor, created_at, updated_at, store_id) '
      "VALUES (?, 1, ?, 0, 1, 'S', 'C', 'c', 'Cash', 'Retail', 'percent', 0, "
      "0, '', 0, '', 1, 1000, 1, 1, 0, 0, 0, 1, 1, 0, 1, 1, ?)",
      [id, 'N$id', store],
    );
  }

  sale('a', 's1');
  sale('b', 's1');
  sale('c', null);
  void pay(String id, String saleId, String method) {
    raw.execute(
      'INSERT INTO payments (id, sale_id, method, amount_minor, status, '
      "occurred_at, created_at) VALUES (?, ?, ?, 100, 'succeeded', 1, 1)",
      [id, saleId, method],
    );
  }

  pay('p1', 'a', 'cash');
  pay('p2', 'b', 'card');
  pay('p3', 'c', 'cash');
  raw.close();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('v13_');
    file = File('${dir.path}/db.sqlite');
  });
  tearDown(() => dir.delete(recursive: true));

  test('a fresh database has payment_methods and payments.method_id', () async {
    final db = AxpertDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, greaterThanOrEqualTo(13));
    expect(await db.select(db.paymentMethodEntries).get(), isEmpty);
    final info = await db.customSelect('PRAGMA table_info(payments)').get();
    expect(info.map((r) => r.read<String>('name')), contains('method_id'));
  });

  test('v12 upgrades: four methods per live store, payments linked', () async {
    await _buildV12(file);
    final db = AxpertDatabase(NativeDatabase(file));
    addTearDown(db.close);

    final v = await db.customSelect('PRAGMA user_version').getSingle();
    expect(v.read<int>('user_version'), db.schemaVersion);

    final methods = await db.select(db.paymentMethodEntries).get();
    expect(methods, hasLength(8)); // s1 and s2; the tombstoned s3 gets none
    expect({for (final m in methods) m.storeId}, {'s1', 's2'});
    expect(methods.every((m) => _uuid4.hasMatch(m.id)), isTrue);
    expect({for (final m in methods) m.id}, hasLength(8));
    final s1 = {
      for (final m in methods.where((m) => m.storeId == 's1')) m.code: m,
    };
    expect(s1.keys.toSet(), {'cash', 'card', 'bank_transfer', 'mobile_money'});
    expect(s1['cash']!.methodType, 'cash');
    expect(s1['cash']!.requiresReference, isFalse);
    expect(s1['bank_transfer']!.requiresReference, isTrue);
    expect(s1['mobile_money']!.requiresReference, isTrue);
    expect(s1.values.every((m) => m.enabled), isTrue);
    expect(
      (s1.values.toList()..sort((a, b) => a.sortOrder - b.sortOrder)).map(
        (m) => m.code,
      ),
      ['cash', 'card', 'bank_transfer', 'mobile_money'],
    );

    final pays = {
      for (final p in await db.select(db.paymentEntries).get()) p.id: p,
    };
    expect(pays['p1']!.methodId, s1['cash']!.id);
    expect(pays['p2']!.methodId, s1['card']!.id);
    expect(pays['p3']!.methodId, isNull); // sale without a store
    expect(pays['p1']!.method, 'cash'); // the history text is kept
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });

  test('a store and a code are unique; the type is restricted', () async {
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
    Future<void> insert(
      String id,
      String code,
      String type,
    ) => db.customStatement(
      'INSERT INTO payment_methods (id, store_id, code, name, type, '
      "created_at, updated_at) VALUES ('$id', 's1', '$code', 'n', '$type', 1, 1)",
    );
    await insert('m1', 'cash', 'cash');
    await expectLater(insert('m2', 'cash', 'cash'), throwsA(anything));
    await expectLater(insert('m3', 'x', 'crypto'), throwsA(anything));
    await insert('m4', 'voucher', 'other');
  });

  test('a failed v13 step rolls back and leaves v12 intact', () async {
    await _buildV12(file);
    final seed = sqlite3.open(file.path);
    // A leftover table of the wrong shape under the new name: its creation is
    // skipped and the backfill fails after payments.method_id was added.
    seed.execute('CREATE TABLE payment_methods (x INTEGER)');
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
    expect(raw.select('PRAGMA user_version').single['user_version'], 12);
    final cols = {
      for (final r in raw.select('PRAGMA table_info(payments)'))
        r['name'] as String,
    };
    expect(cols, isNot(contains('method_id')));
    expect(raw.select('SELECT count(*) AS n FROM payments').single['n'], 3);
    expect(
      raw.select('PRAGMA table_info(payment_methods)').map((r) => r['name']),
      ['x'],
    );
  });
}
