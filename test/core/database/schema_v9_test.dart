import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/database/axpert_database.dart';

/// The v8 shape of the four tables v9 alters, with one row of data each.
const _v8 = <String>[
  'CREATE TABLE products (id TEXT NOT NULL, legacy_id INTEGER NOT NULL UNIQUE, '
      'position INTEGER NOT NULL, name TEXT NOT NULL, code TEXT NOT NULL, '
      'barcode TEXT NOT NULL, price_minor INTEGER NOT NULL, '
      "currency_code TEXT NOT NULL DEFAULT 'INR', category TEXT NOT NULL, "
      'sub TEXT NOT NULL, stock INTEGER NOT NULL, gst_bp INTEGER NOT NULL, '
      'image INTEGER NOT NULL, favourite INTEGER NOT NULL, '
      'created_at TEXT NOT NULL, updated_at TEXT NOT NULL, deleted_at TEXT, '
      'server_id TEXT, server_version INTEGER, device_id TEXT, PRIMARY KEY (id))',
  'CREATE TABLE held_bills (id TEXT NOT NULL, ref TEXT NOT NULL, '
      'position INTEGER NOT NULL, held_at TEXT NOT NULL, cart_json TEXT NOT NULL, '
      'created_at TEXT NOT NULL, updated_at TEXT NOT NULL, deleted_at TEXT, '
      'PRIMARY KEY (id))',
  'CREATE TABLE sales (id TEXT NOT NULL, has_sale_id INTEGER NOT NULL, '
      'number TEXT NOT NULL, position INTEGER NOT NULL, '
      'occurred_at TEXT NOT NULL, store_name TEXT NOT NULL, '
      'customer_name TEXT NOT NULL, customer_legacy_id TEXT NOT NULL, '
      'customer_id TEXT, currency_code TEXT NOT NULL, mode TEXT NOT NULL, '
      'total_minor INTEGER NOT NULL, created_at TEXT NOT NULL, '
      'updated_at TEXT NOT NULL, deleted_at TEXT, PRIMARY KEY (id))',
  'CREATE TABLE sale_lines (id TEXT NOT NULL, sale_id TEXT NOT NULL, '
      'line_no INTEGER NOT NULL, product_id TEXT, price_minor INTEGER NOT NULL, '
      'qty_milli INTEGER NOT NULL, discount_bp INTEGER NOT NULL, '
      'returned_qty_milli INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, '
      'PRIMARY KEY (id))',
  "INSERT INTO products VALUES ('p1', 1, 0, 'Cola', 'C1', 'B1', 4000, 'INR', "
      "'Beverages', 'Soft Drinks', 10, 1800, 2, 1, 'x', 'x', NULL, NULL, NULL, NULL)",
  "INSERT INTO held_bills VALUES ('h1', 'H1', 0, 't', '{}', 'x', 'x', NULL)",
  "INSERT INTO sales VALUES ('s1', 1, 'AX000001', 0, 't', 'MAISON', 'Walk-in', "
      "'walk', NULL, 'INR', 'Cash', 4720, 'x', 'x', NULL)",
  "INSERT INTO sale_lines VALUES ('l1', 's1', 0, 'p1', 4000, 1000, 0, 0, 'x')",
];

void main() {
  void seedV8(dynamic db, {String extra = ''}) {
    for (final sql in _v8) {
      db.execute(sql);
    }
    if (extra.isNotEmpty) db.execute(extra);
    db.execute('PRAGMA user_version = 8');
  }

  Future<List<String>> columns(AxpertDatabase db, String table) async => [
    for (final r in await db.customSelect('PRAGMA table_info($table)').get())
      r.read<String>('name'),
  ];

  test('v8 to v9 adds the tables and columns and keeps every row', () async {
    final db = AxpertDatabase(NativeDatabase.memory(setup: (d) => seedV8(d)));
    addTearDown(db.close);

    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 10);

    final tables = {
      for (final r
          in await db
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type = 'table'",
              )
              .get())
        r.read<String>('name'),
    };
    expect(
      tables,
      containsAll(<String>[
        'currencies',
        'stores',
        'counters',
        'users',
        'user_access',
        'categories',
        'offers',
        'seed_manifest',
      ]),
    );

    expect(
      await columns(db, 'products'),
      containsAll([
        'store_id',
        'category_id',
        'variant_group',
        'variant_label',
      ]),
    );
    expect(await columns(db, 'held_bills'), contains('store_id'));
    expect(
      await columns(db, 'sales'),
      containsAll(['store_id', 'counter_id', 'user_id', 'user_name']),
    );
    expect(
      await columns(db, 'sale_lines'),
      containsAll([
        'offer_kind',
        'offer_name',
        'offer_saving_minor',
        'offer_unit_off_minor',
        'is_gift',
      ]),
    );

    final product = await db.select(db.productEntries).getSingle();
    expect(product.name, 'Cola');
    expect(product.priceMinor, 4000);
    expect(product.storeId, isNull);
    expect(product.variantGroup, isNull);
    final held = await db.select(db.heldBillEntries).getSingle();
    expect(held.ref, 'H1');
    expect(held.storeId, isNull);
    // The trimmed v8 sales tables lack columns Drift reads, so use SQL.
    final sale = await db
        .customSelect('SELECT number, store_id, user_name FROM sales')
        .getSingle();
    expect(sale.read<String>('number'), 'AX000001');
    expect(sale.data['store_id'], isNull);
    expect(sale.data['user_name'], isNull);
    final line = await db
        .customSelect('SELECT price_minor, offer_kind, is_gift FROM sale_lines')
        .getSingle();
    expect(line.read<int>('price_minor'), 4000);
    expect(line.data['offer_kind'], isNull);
    expect(line.read<int>('is_gift'), 0);
  });

  test('a fresh database is created at v9 with the same tables', () async {
    final db = AxpertDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 10);
    expect(await db.select(db.offerEntries).get(), isEmpty);
    expect(await db.select(db.storeEntries).get(), isEmpty);
  });

  test('a failed v9 upgrade rolls back and leaves v8 data intact', () async {
    dynamic raw;
    final db = AxpertDatabase(
      NativeDatabase.memory(
        setup: (d) {
          raw = d;
          // `offers` is created late in the step, so the tables created
          // before it must be rolled back too.
          seedV8(d, extra: 'CREATE INDEX offers ON products (name)');
        },
      ),
    );
    addTearDown(() async {
      try {
        await db.close();
      } on Object {
        // The migration failed on purpose.
      }
    });

    await expectLater(
      db.customSelect('SELECT 1').getSingle(),
      throwsA(anything),
    );

    expect(raw.select('PRAGMA user_version').single['user_version'], 8);
    expect(raw.select('SELECT name FROM products').single['name'], 'Cola');
    final names = {
      for (final r in raw.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ))
        r['name'] as String,
    };
    expect(names, isNot(contains('currencies')));
    expect(names, isNot(contains('stores')));
    final cols = {
      for (final r in raw.select('PRAGMA table_info(products)'))
        r['name'] as String,
    };
    expect(cols, isNot(contains('store_id')));
  });

  group('offers constraints', () {
    late AxpertDatabase db;
    setUp(() => db = AxpertDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    Future<void> product() => db.customStatement(
      'INSERT INTO products (id, legacy_id, position, name, code, barcode, '
      'price_minor, category, sub, stock, gst_bp, image, favourite, '
      "created_at, updated_at) VALUES ('p1', 1, 0, 'Cola', 'C1', 'B1', 4000, "
      "'B', 'S', 10, 1800, 2, 1, 'x', 'x')",
    );

    Future<void> offer(String values) => db.customStatement(
      'INSERT INTO offers (id, kind, name, product_id, percent_bp, '
      'fixed_amount_minor, currency_code, min_cart_minor, gift_product_id, '
      "created_at, updated_at) VALUES ('o', $values, 'x', 'x')",
    );

    test('valid rows of each kind are accepted', () async {
      await product();
      await offer("'discount', 'n', 'p1', 2000, NULL, NULL, NULL, NULL");
      await db.customStatement('DELETE FROM offers');
      await offer("'discount', 'n', 'p1', NULL, 3000, 'INR', NULL, NULL");
      await db.customStatement('DELETE FROM offers');
      await offer("'promotion', 'n', 'p1', 5000, NULL, NULL, NULL, NULL");
      await db.customStatement('DELETE FROM offers');
      await offer("'gift_tier', 'n', NULL, NULL, NULL, 'INR', 50000, 'p1'");
    });

    test('rows that break a kind rule are rejected', () async {
      await product();
      // discount with both percent and fixed
      await expectLater(
        offer("'discount', 'n', 'p1', 2000, 3000, 'INR', NULL, NULL"),
        throwsA(anything),
      );
      // fixed amount without currency
      await expectLater(
        offer("'discount', 'n', 'p1', NULL, 3000, NULL, NULL, NULL"),
        throwsA(anything),
      );
      // promotion without product
      await expectLater(
        offer("'promotion', 'n', NULL, 5000, NULL, NULL, NULL, NULL"),
        throwsA(anything),
      );
      // gift tier without a threshold
      await expectLater(
        offer("'gift_tier', 'n', NULL, NULL, NULL, 'INR', NULL, 'p1'"),
        throwsA(anything),
      );
      // percent out of range
      await expectLater(
        offer("'promotion', 'n', 'p1', 10001, NULL, NULL, NULL, NULL"),
        throwsA(anything),
      );
      // unknown kind
      await expectLater(
        offer("'other', 'n', 'p1', 5000, NULL, NULL, NULL, NULL"),
        throwsA(anything),
      );
    });
  });
}
