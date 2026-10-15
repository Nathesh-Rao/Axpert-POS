import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/migration/sale_rows.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' show Database, sqlite3;

const _isoMs = '2026-10-07T11:27:08.123Z';
const _isoMicro = '2026-10-07T11:27:08.123456Z';
const _isoNoFrac = '2026-10-07T11:27:08Z';
const _isoOffset = '2026-10-07T16:57:08+05:30';
const _isoOffsetFrac = '2026-10-07T16:57:08.250+05:30';

final _base = DateTime.utc(2026, 10, 7, 11, 27, 8).millisecondsSinceEpoch;

void _insert(Database raw, String table, Map<String, Object?> row) {
  final cols = row.keys.map((c) => '"$c"').join(', ');
  final marks = List.filled(row.length, '?').join(', ');
  raw.execute(
    'INSERT INTO "$table" ($cols) VALUES ($marks)',
    row.values.toList(),
  );
}

/// A database exactly as v10 stored it: TEXT stamps, and every foreign key
/// turned into ON DELETE CASCADE so that a rebuild which drops a parent with
/// foreign keys on would silently delete its children.
Future<void> _buildV10(File file) async {
  final seed = AxpertDatabase(NativeDatabase(file));
  await seed.customSelect('SELECT 1').get();
  await seed.close();

  final raw = sqlite3.open(file.path);
  raw.execute('PRAGMA foreign_keys = OFF');
  // v10 has neither the v12 tables nor the v12 store column.
  raw.execute('DROP TABLE inventory_transactions');
  raw.execute('DROP TABLE inventory_balance');
  raw.execute('ALTER TABLE stores DROP COLUMN allow_negative_stock');
  final tables = raw.select(
    "SELECT name, sql FROM sqlite_master WHERE type = 'table' "
    "AND name NOT LIKE 'sqlite_%'",
  );
  for (final t in tables.toList()) {
    final name = t['name'] as String;
    final indexes = [
      for (final r in raw.select(
        "SELECT sql FROM sqlite_master WHERE type = 'index' "
        'AND tbl_name = ? AND sql IS NOT NULL',
        [name],
      ))
        r['sql'] as String,
    ];
    var ddl = t['sql'] as String;
    ddl = ddl.replaceAllMapped(
      RegExp(r'("?\w*_at"?)\s+INTEGER'),
      (m) => '${m[1]} TEXT',
    );
    ddl = ddl.replaceAllMapped(
      RegExp(r'REFERENCES\s+("?\w+"?)\s*\(\s*("?\w+"?)\s*\)'),
      (m) => 'REFERENCES ${m[1]} (${m[2]}) ON DELETE CASCADE',
    );
    raw.execute('DROP TABLE "$name"');
    raw.execute(ddl);
    indexes.forEach(raw.execute);
  }
  raw.execute('PRAGMA user_version = 10');
  raw.execute('PRAGMA foreign_keys = ON');
  _seedRows(raw);
  raw.close();
}

void _seedRows(Database raw) {
  _insert(raw, 'currencies', {
    'code': 'INR',
    'name': 'Rupee',
    'symbol': 'R',
    'exponent': 2,
    'grouping': 'lakh',
    'created_at': _isoMs,
    'updated_at': _isoMs,
  });
  _insert(raw, 'stores', {
    'id': 's1',
    'name': 'Shop',
    'currency_code': 'INR',
    'created_at': _isoMicro,
    'updated_at': _isoNoFrac,
  });
  _insert(raw, 'stores', {
    'id': 's2',
    'name': 'Closed',
    'currency_code': 'INR',
    'created_at': _isoOffset,
    'updated_at': _isoOffsetFrac,
    'deleted_at': _isoMs,
  });
  _insert(raw, 'counters', {
    'id': 'c1',
    'store_id': 's1',
    'name': 'Counter 1',
    'created_at': _isoMs,
    'updated_at': _isoMs,
  });
  for (final (id, stamp) in [('u1', 'garbage'), ('u2', ''), ('u3', _isoMs)]) {
    _insert(raw, 'users', {
      'id': id,
      'username': id,
      'display_name': id,
      'role': 'cashier',
      'salt': 's',
      'password_hash': 'h',
      'hash_algo': 'a',
      'created_at': _isoMs,
      'updated_at': stamp,
    });
  }
  _insert(raw, 'user_access', {
    'id': 'ua1',
    'user_id': 'u3',
    'store_id': 's1',
    'counter_id': 'c1',
  });
  _insert(raw, 'categories', {
    'id': 'cat1',
    'name': 'Drinks',
    'created_at': _isoMs,
    'updated_at': _isoMs,
    'store_id': 's1',
  });
  _insert(raw, 'products', {
    'id': 'p1',
    'legacy_id': 1,
    'position': 0,
    'name': 'Tea',
    'code': 'T1',
    'barcode': 'b1',
    'price_minor': 1000,
    'category': 'Drinks',
    'sub': 'Hot',
    'stock': 5,
    'gst_bp': 500,
    'image': -1,
    'favourite': 0,
    'created_at': _isoMicro,
    'updated_at': _isoMs,
    'store_id': 's1',
    'category_id': 'cat1',
  });
  _insert(raw, 'customers', {
    'id': 'cu1',
    'legacy_id': 'c9',
    'position': 0,
    'name': 'Asha',
    'phone': '',
    'email': '',
    'member_no': 'M1',
    'points': 0,
    'created_at': _isoMs,
    'updated_at': _isoMs,
  });
  for (final (id, date) in [
    ('sa1', _isoMs),
    ('sa2', _isoMicro),
    ('sa3', _isoNoFrac),
    ('sa4', _isoOffset),
  ]) {
    _insert(raw, 'sales', {
      'id': id,
      'has_sale_id': 1,
      'number': 'AX$id',
      'position': 0,
      'occurred_at': date,
      'store_name': 'Shop',
      'customer_name': 'Asha',
      'customer_legacy_id': 'c9',
      'mode': 'Cash',
      'sale_type': 'Retail',
      'bill_discount_type': 'percent',
      'bill_discount_bp': 0,
      'bill_discount_minor': 0,
      'discount_reason': '',
      'points_redeemed': 0,
      'note': '',
      'items': 1,
      'qty_milli': 1000,
      'value_minor': 1000,
      'subtotal_minor': 1000,
      'discount_minor': 0,
      'tax_minor': 50,
      'points_minor': 0,
      'total_minor': 1050,
      'tendered_minor': 1050,
      'change_minor': 0,
      'created_at': date,
      'updated_at': date,
      'store_id': 's1',
      'customer_id': 'cu1',
      'user_id': 'u3',
      'counter_id': 'c1',
    });
    _insert(raw, 'sale_lines', {
      'id': 'l$id',
      'sale_id': id,
      'line_no': 0,
      'product_legacy_id': 1,
      'product_name': 'Tea',
      'product_code': 'T1',
      'product_barcode': 'b1',
      'product_price_minor': 1000,
      'product_category': 'Drinks',
      'product_sub': 'Hot',
      'product_stock': 5,
      'product_gst_bp': 500,
      'product_image': -1,
      'product_favourite': 0,
      'price_minor': 1000,
      'qty_milli': 1000,
      'discount_bp': 0,
      'created_at': date,
      'product_id': 'p1',
    });
    _insert(raw, 'payments', {
      'id': 'pay$id',
      'sale_id': id,
      'method': 'cash',
      'amount_minor': 1050,
      'status': 'succeeded',
      'occurred_at': date,
      'created_at': date,
    });
  }
  _insert(raw, 'held_bills', {
    'id': 'h1',
    'ref': 'H1',
    'position': 0,
    'held_at': _isoOffsetFrac,
    'cart_json': '{}',
    'created_at': _isoMs,
    'updated_at': _isoMs,
    'store_id': 's1',
  });
  _insert(raw, 'current_cart', {'cart_json': '{}', 'updated_at': _isoMicro});
  _insert(raw, 'settings', {
    'key': 'axpert-dark',
    'value_json': 'true',
    'updated_at': _isoMs,
  });
  _insert(raw, 'offers', {
    'id': 'o1',
    'kind': 'discount',
    'name': 'Tea off',
    'percent_bp': 1000,
    'created_at': _isoMs,
    'updated_at': _isoMs,
    'ends_at': _isoOffset,
    'store_id': 's1',
    'product_id': 'p1',
  });
  _insert(raw, 'store_forex', {
    'id': 'f1',
    'store_id': 's1',
    'foreign_currency_code': 'INR',
    'rate_micro': 1000000,
    'created_at': _isoMs,
    'updated_at': _isoMs,
  });
  _insert(raw, 'tax_regimes', {
    'id': 'r1',
    'region': 'IN',
    'label': 'GST',
    'price_mode': 'exclusive',
    'created_at': _isoMs,
    'updated_at': _isoMs,
  });
  _insert(raw, 'tax_slabs', {'id': 'sl1', 'regime_id': 'r1', 'rate_bp': 500});
  _insert(raw, 'migration_state', {'key': 'k', 'value': 'v'});
  _insert(raw, 'seed_manifest', {'table_name': 'stores', 'row_id': 's1'});
  _insert(raw, 'device_context_entries', {'device_id': 'd1'});
}

Map<String, int> _counts(Database raw) => {
  for (final t in raw.select(
    "SELECT name FROM sqlite_master WHERE type = 'table' "
    "AND name NOT LIKE 'sqlite_%'",
  ))
    t['name'] as String:
        raw.select('SELECT count(*) AS n FROM "${t['name']}"').single['n']
            as int,
};

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;
  late File file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('v11_');
    file = File('${dir.path}/db.sqlite');
  });
  tearDown(() => dir.delete(recursive: true));

  test('a fresh database has INTEGER stamps', () async {
    final db = AxpertDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, greaterThanOrEqualTo(11));
    final info = await db.customSelect('PRAGMA table_info(stores)').get();
    final types = {
      for (final r in info) r.read<String>('name'): r.read<String>('type'),
    };
    expect(types['created_at'], 'INTEGER');
    expect(types['deleted_at'], 'INTEGER');
  });

  test('v10 upgrades: values, NULLs, counts, foreign keys', () async {
    await _buildV10(file);
    final before = sqlite3.open(file.path);
    final countsBefore = _counts(before);
    expect(before.select('PRAGMA user_version').single['user_version'], 10);
    // The seed really is v10-shaped: TEXT stamps and cascading children.
    expect(
      before.select('SELECT typeof(created_at) AS t FROM stores').first['t'],
      'text',
    );
    expect(
      before
          .select("SELECT sql FROM sqlite_master WHERE name = 'sale_lines'")
          .single['sql'],
      contains('ON DELETE CASCADE'),
    );
    before.close();

    final db = AxpertDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final v = await db.customSelect('PRAGMA user_version').getSingle();
    expect(v.read<int>('user_version'), db.schemaVersion);

    // Row counts of ALL tables (parents and children) are unchanged.
    final after = <String, int>{};
    for (final name in countsBefore.keys) {
      final r = await db
          .customSelect('SELECT count(*) AS n FROM "$name"')
          .getSingle();
      after[name] = r.read<int>('n');
    }
    // Only `migration_state` grows from v11 (the step's own report row).
    expect(after, {
      ...countsBefore,
      'migration_state': countsBefore['migration_state']! + 1,
      // v13 (same upgrade chain) seeds four methods for the live store.
      'payment_methods': 4,
      // v14 seeds the eight units and the barcode of the one product.
      'units': 8,
      'product_barcodes': 1,
    });
    expect(countsBefore['sale_lines'], 4);
    expect(countsBefore['payments'], 4);

    // Foreign keys are on again and consistent; the cascades survived.
    final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(fk.read<int>('foreign_keys'), 1);
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    final lines = await db
        .customSelect("SELECT sql FROM sqlite_master WHERE name = 'sale_lines'")
        .getSingle();
    expect(lines.read<String>('sql'), contains('ON DELETE CASCADE'));

    // Exact milliseconds for every ISO shape.
    final stores = {
      for (final s in await db.select(db.storeEntries).get()) s.id: s,
    };
    expect(stores['s1']!.createdAt, _base + 123); // micro truncated
    expect(stores['s1']!.updatedAt, _base); // no fraction
    expect(stores['s1']!.deletedAt, isNull); // NULL stays NULL, never 0
    expect(stores['s2']!.createdAt, _base); // +05:30
    expect(stores['s2']!.updatedAt, _base + 250); // +05:30 with fraction
    expect(stores['s2']!.deletedAt, _base + 123);
    final offer = await db.select(db.offerEntries).getSingle();
    expect(offer.startsAt, isNull);
    expect(offer.endsAt, _base);
    final held = await db.select(db.heldBillEntries).getSingle();
    expect(held.heldAt, _base + 250);
    expect((await db.select(db.productEntries).getSingle()).deletedAt, isNull);

    // Only non-null unparsable values become 0, and they are counted.
    final users = {
      for (final u in await db.select(db.userEntries).get()) u.id: u.updatedAt,
    };
    expect(users, {'u1': 0, 'u2': 0, 'u3': _base + 123});
    final state = await (db.select(
      db.migrationStateEntries,
    )..where((t) => t.key.equals('epoch_v11'))).getSingle();
    final report = jsonDecode(state.value) as Map<String, dynamic>;
    expect(report['unparsable_total'], 2);
    expect(report['unparsable'], {'users.updated_at': 2});

    // No `*_at` value is text any more, in any table.
    for (final name in countsBefore.keys) {
      final info = await db.customSelect('PRAGMA table_info("$name")').get();
      for (final c in info.map((r) => r.read<String>('name'))) {
        if (!c.endsWith('_at')) continue;
        final bad = await db
            .customSelect(
              'SELECT count(*) AS n FROM "$name" '
              'WHERE "$c" IS NOT NULL AND typeof("$c") != \'integer\'',
            )
            .getSingle();
        expect(bad.read<int>('n'), 0, reason: '$name.$c');
      }
    }
  });

  test('the upgraded tables match a fresh database (columns, indexes)', () async {
    await _buildV10(file);
    final db = AxpertDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final fresh = AxpertDatabase(NativeDatabase.memory());
    addTearDown(fresh.close);

    Future<Map<String, List<String>>> shape(AxpertDatabase d) async {
      final out = <String, List<String>>{};
      final names = await d
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%' ORDER BY name",
          )
          .get();
      for (final n in names.map((r) => r.read<String>('name'))) {
        final info = await d.customSelect('PRAGMA table_info("$n")').get();
        final idx = await d
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index' "
              "AND tbl_name = '$n' AND name NOT LIKE 'sqlite_%' ORDER BY name",
            )
            .get();
        out[n] = [
          for (final c in info)
            '${c.read<String>('name')}|${c.read<String>('type')}|'
                '${c.read<int>('notnull')}|${c.readNullable<String>('dflt_value')}|'
                '${c.read<int>('pk')}',
          for (final i in idx) 'index ${i.read<String>('name')}',
        ];
      }
      return out;
    }

    expect(await shape(db), await shape(fresh));
  });

  test(
    'stored sale dates read back as the same instant, canonical form',
    () async {
      await _buildV10(file);
      final db = AxpertDatabase(NativeDatabase(file));
      addTearDown(db.close);
      final read = await SaleRows.read(db);
      final dates = {for (final s in read.list) s.number: s.date};
      // Canonical shape (what React and the web write): byte-identical.
      expect(dates['AXsa1'], _isoMs);
      // Other shapes keep the instant and are written in the canonical form.
      expect(dates['AXsa2'], '2026-10-07T11:27:08.123Z');
      expect(dates['AXsa3'], '2026-10-07T11:27:08.000Z');
      expect(dates['AXsa4'], '2026-10-07T11:27:08.000Z');
    },
  );

  test('a failed v11 step rolls back and leaves v10 data intact', () async {
    await _buildV10(file);
    final seed = sqlite3.open(file.path);
    final countsBefore = _counts(seed);
    // `tax_regimes` is the last table rebuilt: a clashing index name makes
    // `CREATE TABLE tax_regimes_new` fail after the others were rebuilt.
    seed.execute('CREATE INDEX tax_regimes_new ON currencies (name)');
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
    expect(raw.select('PRAGMA user_version').single['user_version'], 10);
    expect(
      raw.select(
        'SELECT typeof(created_at) AS t, created_at AS v FROM stores WHERE id = ?',
        ['s1'],
      ).single,
      {'t': 'text', 'v': _isoMicro},
    );
    final names = {
      for (final r in raw.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ))
        r['name'] as String,
    };
    expect(names.where((n) => n.endsWith('_new')), isEmpty);
    expect(_counts(raw), countsBefore);
    expect(
      raw
          .select(
            "SELECT count(*) AS n FROM migration_state WHERE key = 'epoch_v11'",
          )
          .single['n'],
      0,
    );
  });
}
