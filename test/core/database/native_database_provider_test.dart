import 'package:pos_application/core/database/database_config.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/database/drift_device_context_store.dart';
import 'package:pos_application/core/device/device_context.dart';
import 'package:pos_application/core/database/native_database_provider.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DatabaseProvider provider;

  setUp(() {
    provider = NativeDatabaseProvider(
      config: const DatabaseConfig(),
      executor: NativeDatabase.memory(
        setup: (database) => database.execute('PRAGMA user_version = 1'),
      ),
    );
  });

  tearDown(() async {
    await provider.close();
  });

  test(
    'migrates version 1 database to device context metadata schema',
    () async {
      final first = await provider.open();
      final second = await provider.open();

      expect(first, same(second));
      expect(first.schemaVersion, 11);
      expect(first.allTables.map((table) => table.actualTableName).toSet(), {
        'device_context_entries',
        'settings',
        'migration_state',
        'customers',
        'held_bills',
        'products',
        'sales',
        'sale_lines',
        'payments',
        'current_cart',
        'currencies',
        'stores',
        'counters',
        'users',
        'user_access',
        'categories',
        'offers',
        'seed_manifest',
        'store_forex',
        'tax_regimes',
        'tax_slabs',
      });
      expect(await first.customSelect('SELECT 1').getSingle(), isNotNull);
      final foreignKeys = await first
          .customSelect('PRAGMA foreign_keys')
          .getSingle();

      expect(foreignKeys.read<int>('foreign_keys'), 1);
    },
  );

  test('migrated schema supports device context storage', () async {
    final database = await provider.open();
    final store = DriftDeviceContextStore(provider);
    const context = DeviceContext(
      deviceId: '4b1f3a52-191c-4dd2-9e19-2da6fd9aec21',
      outletId: 'outlet-reference',
      registerId: 'register-reference',
    );

    await store.write(context);

    expect(database.schemaVersion, 11);
    expect(await store.read(), context);
  });

  test('exposes Drift transaction support through database access', () async {
    final database = await provider.open();
    var completed = false;

    await database.transaction(() async {
      completed = true;
      expect(await database.customSelect('SELECT 1').getSingle(), isNotNull);
    });

    expect(completed, isTrue);
  });

  test('rolls back all statements when a transaction fails', () async {
    final database = await provider.open();
    await database.customStatement(
      'CREATE TABLE transaction_probe (value INTEGER NOT NULL)',
    );

    await expectLater(
      database.transaction(() async {
        await database.customStatement(
          'INSERT INTO transaction_probe (value) VALUES (1)',
        );
        throw StateError('force transaction rollback');
      }),
      throwsStateError,
    );

    final rows = await database
        .customSelect('SELECT COUNT(*) AS count FROM transaction_probe')
        .getSingle();
    expect(rows.read<int>('count'), 0);
  });

  group('schema v2 to v3 upgrade', () {
    const v2Ddl =
        'CREATE TABLE device_context_entries ('
        'singleton_id INTEGER NOT NULL DEFAULT 1, '
        'device_id TEXT NOT NULL, outlet_id TEXT NULL, register_id TEXT NULL, '
        'PRIMARY KEY (singleton_id))';

    void seedV2(dynamic database, {String extra = ''}) {
      database.execute(v2Ddl);
      database.execute(
        "INSERT INTO device_context_entries (device_id) VALUES ('dev-1')",
      );
      if (extra.isNotEmpty) database.execute(extra);
      database.execute('PRAGMA user_version = 2');
    }

    test('adds settings tables and preserves existing data', () async {
      final database = AxpertDatabase(
        NativeDatabase.memory(setup: (db) => seedV2(db)),
      );
      addTearDown(database.close);

      final tables = await database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      final names = tables.map((row) => row.read<String>('name')).toSet();
      final device = await database
          .customSelect('SELECT device_id FROM device_context_entries')
          .getSingle();
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();

      expect(names, containsAll(['settings', 'migration_state', 'customers']));
      expect(device.read<String>('device_id'), 'dev-1');
      expect(version.read<int>('user_version'), 11);
    });

    test('failed upgrade rolls back and leaves data intact', () async {
      // An index named migration_state makes the second createTable fail.
      dynamic raw;
      final database = AxpertDatabase(
        NativeDatabase.memory(
          setup: (db) {
            raw = db;
            seedV2(
              db,
              extra:
                  'CREATE INDEX migration_state ON device_context_entries '
                  '(device_id)',
            );
          },
        ),
      );

      addTearDown(() async {
        try {
          await database.close();
        } on Object {
          // The migration failed on purpose; closing may fail too.
        }
      });

      await expectLater(
        database.customSelect('SELECT 1').getSingle(),
        throwsA(anything),
      );

      // Inspect through the raw handle: the Drift connection would re-run
      // the failing migration on every further query.
      final tables = raw.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = {for (final row in tables) row['name'] as String};
      final device = raw.select('SELECT device_id FROM device_context_entries');
      final version = raw.select('PRAGMA user_version');

      expect(names, isNot(contains('settings')));
      expect(device.single['device_id'], 'dev-1');
      expect(version.single['user_version'], 2);
    });
  });

  group('schema v3 to v4 upgrade', () {
    const v3Ddl = [
      'CREATE TABLE device_context_entries ('
          'singleton_id INTEGER NOT NULL DEFAULT 1, '
          'device_id TEXT NOT NULL, outlet_id TEXT NULL, register_id TEXT NULL, '
          'PRIMARY KEY (singleton_id))',
      'CREATE TABLE settings (key TEXT NOT NULL, value_json TEXT NOT NULL, '
          'updated_at TEXT NOT NULL, PRIMARY KEY (key))',
      'CREATE TABLE migration_state (key TEXT NOT NULL, value TEXT NOT NULL, '
          'PRIMARY KEY (key))',
      "INSERT INTO device_context_entries (device_id) VALUES ('dev-1')",
      "INSERT INTO settings VALUES ('axpert-dark', 'true', 0)",
    ];

    void seedV3(dynamic database, {String extra = ''}) {
      for (final sql in v3Ddl) {
        database.execute(sql);
      }
      if (extra.isNotEmpty) database.execute(extra);
      database.execute('PRAGMA user_version = 3');
    }

    test('adds customers and preserves existing data', () async {
      final database = AxpertDatabase(
        NativeDatabase.memory(setup: (db) => seedV3(db)),
      );
      addTearDown(database.close);

      final tables = await database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      final names = tables.map((row) => row.read<String>('name')).toSet();
      final setting = await database
          .customSelect('SELECT value_json FROM settings')
          .getSingle();
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();

      expect(names, contains('customers'));
      expect(setting.read<String>('value_json'), 'true');
      expect(version.read<int>('user_version'), 11);
    });

    test('failed upgrade leaves v3 data and user_version intact', () async {
      dynamic raw;
      final database = AxpertDatabase(
        NativeDatabase.memory(
          setup: (db) {
            raw = db;
            seedV3(db, extra: 'CREATE INDEX customers ON settings (key)');
          },
        ),
      );

      addTearDown(() async {
        try {
          await database.close();
        } on Object {
          // The migration failed on purpose; closing may fail too.
        }
      });

      await expectLater(
        database.customSelect('SELECT 1').getSingle(),
        throwsA(anything),
      );

      final tables = raw.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = {for (final row in tables) row['name'] as String};
      expect(names, isNot(contains('customers')));
      expect(
        raw.select('SELECT value_json FROM settings').single['value_json'],
        'true',
      );
      expect(raw.select('PRAGMA user_version').single['user_version'], 3);
    });
  });

  group('schema v4 to v5 upgrade', () {
    const v4Ddl = [
      'CREATE TABLE device_context_entries ('
          'singleton_id INTEGER NOT NULL DEFAULT 1, '
          'device_id TEXT NOT NULL, outlet_id TEXT NULL, register_id TEXT NULL, '
          'PRIMARY KEY (singleton_id))',
      'CREATE TABLE settings (key TEXT NOT NULL, value_json TEXT NOT NULL, '
          'updated_at TEXT NOT NULL, PRIMARY KEY (key))',
      'CREATE TABLE migration_state (key TEXT NOT NULL, value TEXT NOT NULL, '
          'PRIMARY KEY (key))',
      'CREATE TABLE customers (id TEXT NOT NULL, legacy_id TEXT NOT NULL UNIQUE, '
          'position INTEGER NOT NULL, name TEXT NOT NULL, phone TEXT NOT NULL, '
          'email TEXT NOT NULL, member_no TEXT NOT NULL, points INTEGER NOT NULL, '
          'created_at TEXT NOT NULL, updated_at TEXT NOT NULL, deleted_at TEXT NULL, '
          'server_id TEXT NULL, server_version INTEGER NULL, device_id TEXT NULL, '
          'PRIMARY KEY (id))',
      "INSERT INTO device_context_entries (device_id) VALUES ('dev-1')",
      "INSERT INTO settings VALUES ('axpert-dark', 'true', 0)",
      "INSERT INTO customers (id, legacy_id, position, name, phone, email, "
          "member_no, points, created_at, updated_at) VALUES "
          "('u1', 'walk', 0, 'Walk-in', '', '', '', 0, 0, 0)",
    ];

    void seedV4(dynamic database, {String extra = ''}) {
      for (final sql in v4Ddl) {
        database.execute(sql);
      }
      if (extra.isNotEmpty) database.execute(extra);
      database.execute('PRAGMA user_version = 4');
    }

    test('adds held_bills and preserves existing data', () async {
      final database = AxpertDatabase(
        NativeDatabase.memory(setup: (db) => seedV4(db)),
      );
      addTearDown(database.close);

      final tables = await database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      final names = tables.map((row) => row.read<String>('name')).toSet();
      final setting = await database
          .customSelect('SELECT value_json FROM settings')
          .getSingle();
      final customer = await database
          .customSelect('SELECT name FROM customers')
          .getSingle();
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      final columns = await database
          .customSelect('PRAGMA table_info(held_bills)')
          .get();

      expect(names, contains('held_bills'));
      expect(setting.read<String>('value_json'), 'true');
      expect(customer.read<String>('name'), 'Walk-in');
      expect(version.read<int>('user_version'), 11);
      expect(columns.map((c) => c.read<String>('name')).toList(), [
        'id',
        'ref',
        'position',
        'held_at',
        'cart_json',
        'created_at',
        'updated_at',
        'deleted_at',
        'store_id',
      ]);
    });

    test('a database already at v5 opens unchanged', () async {
      final database = AxpertDatabase(
        NativeDatabase.memory(setup: (db) => seedV4(db)),
      );
      addTearDown(database.close);
      await database.customSelect('SELECT 1').getSingle();
      await database.customStatement(
        "INSERT INTO held_bills (id, ref, position, held_at, cart_json, created_at, updated_at, deleted_at) VALUES ('u', 'H1', 0, 0, '{}', 0, 0, NULL)",
      );
      expect(
        (await database.customSelect('SELECT ref FROM held_bills').getSingle())
            .read<String>('ref'),
        'H1',
      );
    });

    test('failed upgrade leaves v4 data and user_version intact', () async {
      dynamic raw;
      final database = AxpertDatabase(
        NativeDatabase.memory(
          setup: (db) {
            raw = db;
            seedV4(db, extra: 'CREATE INDEX held_bills ON settings (key)');
          },
        ),
      );

      addTearDown(() async {
        try {
          await database.close();
        } on Object {
          // The migration failed on purpose; closing may fail too.
        }
      });

      await expectLater(
        database.customSelect('SELECT 1').getSingle(),
        throwsA(anything),
      );

      final tables = raw.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = {for (final row in tables) row['name'] as String};
      expect(names, isNot(contains('held_bills')));
      expect(
        raw.select('SELECT value_json FROM settings').single['value_json'],
        'true',
      );
      expect(
        raw.select('SELECT name FROM customers').single['name'],
        'Walk-in',
      );
      expect(raw.select('PRAGMA user_version').single['user_version'], 4);
    });
  });

  group('schema v5 to v6 upgrade', () {
    const v5Ddl = [
      'CREATE TABLE device_context_entries ('
          'singleton_id INTEGER NOT NULL DEFAULT 1, '
          'device_id TEXT NOT NULL, outlet_id TEXT NULL, register_id TEXT NULL, '
          'PRIMARY KEY (singleton_id))',
      'CREATE TABLE settings (key TEXT NOT NULL, value_json TEXT NOT NULL, '
          'updated_at TEXT NOT NULL, PRIMARY KEY (key))',
      'CREATE TABLE migration_state (key TEXT NOT NULL, value TEXT NOT NULL, '
          'PRIMARY KEY (key))',
      'CREATE TABLE held_bills (id TEXT NOT NULL, ref TEXT NOT NULL, '
          'position INTEGER NOT NULL, held_at TEXT NOT NULL, '
          'cart_json TEXT NOT NULL, created_at TEXT NOT NULL, '
          'updated_at TEXT NOT NULL, deleted_at TEXT NULL, PRIMARY KEY (id))',
      "INSERT INTO settings VALUES ('axpert-dark', 'true', 0)",
      "INSERT INTO held_bills (id, ref, position, held_at, cart_json, created_at, updated_at, deleted_at) VALUES ('u', 'H1', 0, 0, '{}', 0, 0, NULL)",
    ];

    void seedV5(dynamic database, {String extra = ''}) {
      for (final sql in v5Ddl) {
        database.execute(sql);
      }
      if (extra.isNotEmpty) database.execute(extra);
      database.execute('PRAGMA user_version = 5');
    }

    test('adds products with its indexes and preserves data', () async {
      final database = AxpertDatabase(
        NativeDatabase.memory(setup: (db) => seedV5(db)),
      );
      addTearDown(database.close);

      final columns = await database
          .customSelect('PRAGMA table_info(products)')
          .get();
      final indexes = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND tbl_name = 'products'",
          )
          .get();
      final held = await database
          .customSelect('SELECT ref FROM held_bills')
          .getSingle();
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();

      expect(columns.map((c) => c.read<String>('name')).toList(), [
        'id',
        'legacy_id',
        'position',
        'name',
        'code',
        'barcode',
        'price_minor',
        'currency_code',
        'category',
        'sub',
        'stock',
        'gst_bp',
        'image',
        'favourite',
        'store_id',
        'category_id',
        'variant_group',
        'variant_label',
        'created_at',
        'updated_at',
        'deleted_at',
        'server_id',
        'server_version',
        'device_id',
      ]);
      expect(
        indexes.map((r) => r.read<String>('name')),
        contains('products_position'),
      );
      expect(held.read<String>('ref'), 'H1');
      expect(version.read<int>('user_version'), 11);
    });

    test('legacy_id is unique, code and barcode are not', () async {
      final database = AxpertDatabase(
        NativeDatabase.memory(setup: (db) => seedV5(db)),
      );
      addTearDown(database.close);
      const insert =
          'INSERT INTO products (id, legacy_id, position, name, code, barcode, '
          "price_minor, category, sub, stock, gst_bp, image, favourite, "
          "created_at, updated_at) VALUES ('%s', %d, 0, 'n', 'C', 'B', 1, "
          "'c', 's', 1, 1800, -1, 0, 0, 0)";

      await database.customStatement(
        insert.replaceFirst('%s', 'a').replaceFirst('%d', '1'),
      );
      await database.customStatement(
        insert.replaceFirst('%s', 'b').replaceFirst('%d', '2'),
      );

      await expectLater(
        database.customStatement(
          insert.replaceFirst('%s', 'c').replaceFirst('%d', '2'),
        ),
        throwsA(anything),
      );
      final row = await database
          .customSelect(
            'SELECT currency_code FROM products WHERE id = ?',
            variables: [Variable.withString('a')],
          )
          .getSingle();
      expect(row.read<String>('currency_code'), 'INR');
    });

    test('failed upgrade leaves v5 data and user_version intact', () async {
      dynamic raw;
      final database = AxpertDatabase(
        NativeDatabase.memory(
          setup: (db) {
            raw = db;
            seedV5(db, extra: 'CREATE INDEX products ON settings (key)');
          },
        ),
      );
      addTearDown(() async {
        try {
          await database.close();
        } on Object {
          // The migration failed on purpose; closing may fail too.
        }
      });

      await expectLater(
        database.customSelect('SELECT 1').getSingle(),
        throwsA(anything),
      );

      final tables = raw.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = {for (final row in tables) row['name'] as String};
      expect(names, isNot(contains('products')));
      expect(raw.select('SELECT ref FROM held_bills').single['ref'], 'H1');
      expect(raw.select('PRAGMA user_version').single['user_version'], 5);
    });
  });

  group('schema v6 to v7 upgrade', () {
    const v6Ddl = [
      // Stand-in so the v9 column addition finds the table.
      'CREATE TABLE held_bills (id TEXT PRIMARY KEY)',
      'CREATE TABLE settings (key TEXT NOT NULL, value_json TEXT NOT NULL, '
          'updated_at TEXT NOT NULL, PRIMARY KEY (key))',
      'CREATE TABLE migration_state (key TEXT NOT NULL, value TEXT NOT NULL, '
          'PRIMARY KEY (key))',
      'CREATE TABLE customers (id TEXT NOT NULL, legacy_id TEXT NOT NULL UNIQUE, '
          'position INTEGER NOT NULL, name TEXT NOT NULL, phone TEXT NOT NULL, '
          'email TEXT NOT NULL, member_no TEXT NOT NULL, points INTEGER NOT NULL, '
          'created_at TEXT NOT NULL, updated_at TEXT NOT NULL, '
          'deleted_at TEXT NULL, server_id TEXT NULL, '
          'server_version INTEGER NULL, device_id TEXT NULL, PRIMARY KEY (id))',
      'CREATE TABLE products (id TEXT NOT NULL, legacy_id INTEGER NOT NULL UNIQUE, '
          'position INTEGER NOT NULL, name TEXT NOT NULL, code TEXT NOT NULL, '
          'barcode TEXT NOT NULL, price_minor INTEGER NOT NULL, '
          "currency_code TEXT NOT NULL DEFAULT 'INR', category TEXT NOT NULL, "
          'sub TEXT NOT NULL, stock INTEGER NOT NULL, gst_bp INTEGER NOT NULL, '
          'image INTEGER NOT NULL, favourite INTEGER NOT NULL, '
          'created_at TEXT NOT NULL, updated_at TEXT NOT NULL, '
          'deleted_at TEXT NULL, server_id TEXT NULL, '
          'server_version INTEGER NULL, device_id TEXT NULL, PRIMARY KEY (id))',
      "INSERT INTO settings VALUES ('axpert-dark', 'true', 0)",
      "INSERT INTO customers VALUES ('c1', 'walk', 0, 'Walk-in', '', '', '', 0, "
          "0, 0, NULL, NULL, NULL, NULL)",
    ];

    void seedV6(dynamic database, {String extra = ''}) {
      for (final sql in v6Ddl) {
        database.execute(sql);
      }
      if (extra.isNotEmpty) database.execute(extra);
      database.execute('PRAGMA user_version = 6');
    }

    test('adds sales, sale_lines and payments and preserves data', () async {
      final database = AxpertDatabase(
        NativeDatabase.memory(setup: (db) => seedV6(db)),
      );
      addTearDown(database.close);

      Future<List<String>> columns(String table) async => [
        for (final r
            in await database.customSelect('PRAGMA table_info($table)').get())
          r.read<String>('name'),
      ];

      expect(await columns('sales'), [
        'id',
        'has_sale_id',
        'number',
        'position',
        'occurred_at',
        'store_name',
        'store_id',
        'counter_id',
        'user_id',
        'user_name',
        'customer_name',
        'customer_legacy_id',
        'customer_id',
        'currency_code',
        'mode',
        'sale_type',
        'bill_discount_type',
        'bill_discount_bp',
        'bill_discount_minor',
        'discount_reason',
        'points_redeemed',
        'note',
        'items',
        'qty_milli',
        'value_minor',
        'subtotal_minor',
        'discount_minor',
        'tax_minor',
        'points_minor',
        'total_minor',
        'tendered_minor',
        'change_minor',
        'returned_order',
        'created_at',
        'updated_at',
        'deleted_at',
        'server_id',
        'server_version',
        'device_id',
      ]);
      expect(await columns('sale_lines'), [
        'id',
        'sale_id',
        'line_no',
        'product_id',
        'product_legacy_id',
        'product_name',
        'product_code',
        'product_barcode',
        'product_price_minor',
        'product_category',
        'product_sub',
        'product_stock',
        'product_gst_bp',
        'product_image',
        'product_favourite',
        'price_minor',
        'qty_milli',
        'discount_bp',
        'offer_kind',
        'offer_name',
        'offer_saving_minor',
        'offer_unit_off_minor',
        'is_gift',
        'returned_qty_milli',
        'created_at',
      ]);
      expect(await columns('payments'), [
        'id',
        'sale_id',
        'method',
        'amount_minor',
        'currency_code',
        'status',
        'occurred_at',
        'created_at',
      ]);
      final indexes = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND tbl_name = 'sales'",
          )
          .get();
      expect(
        indexes.map((r) => r.read<String>('name')),
        contains('sales_position'),
      );
      final customer = await database
          .customSelect('SELECT legacy_id FROM customers')
          .getSingle();
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(customer.read<String>('legacy_id'), 'walk');
      expect(version.read<int>('user_version'), 11);
    });

    test('number is not unique and a link must point at a real row', () async {
      final database = AxpertDatabase(
        NativeDatabase.memory(setup: (db) => seedV6(db)),
      );
      addTearDown(database.close);
      String insert(String id, {String customer = 'NULL'}) =>
          'INSERT INTO sales (id, has_sale_id, number, position, occurred_at, store_name, '
          'customer_name, customer_legacy_id, customer_id, mode, sale_type, '
          'bill_discount_type, bill_discount_bp, bill_discount_minor, '
          'discount_reason, points_redeemed, note, items, qty_milli, '
          'value_minor, subtotal_minor, discount_minor, tax_minor, '
          'points_minor, total_minor, tendered_minor, change_minor, '
          "created_at, updated_at) VALUES ('$id', 0, 'AX000001', 0, 't', 's', "
          "'n', 'walk', $customer, 'Cash', 'Cash', 'flat', 0, 0, '', 0, '', "
          "1, 1000, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0)";

      await database.customStatement(insert('a'));
      await database.customStatement(insert('b'));
      await database.customStatement(insert('c', customer: "'c1'"));
      await expectLater(
        database.customStatement(insert('d', customer: "'missing'")),
        throwsA(anything),
      );
    });

    test('failed upgrade leaves v6 data and user_version intact', () async {
      dynamic raw;
      final database = AxpertDatabase(
        NativeDatabase.memory(
          setup: (db) {
            raw = db;
            seedV6(db, extra: 'CREATE INDEX sale_lines ON settings (key)');
          },
        ),
      );
      addTearDown(() async {
        try {
          await database.close();
        } on Object {
          // The migration failed on purpose; closing may fail too.
        }
      });

      await expectLater(
        database.customSelect('SELECT 1').getSingle(),
        throwsA(anything),
      );

      final tables = raw.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final names = {for (final row in tables) row['name'] as String};
      expect(names, isNot(contains('sales')));
      expect(names, isNot(contains('payments')));
      expect(
        raw.select('SELECT key FROM settings').single['key'],
        'axpert-dark',
      );
      expect(raw.select('PRAGMA user_version').single['user_version'], 6);
    });
  });

  group('schema v7 to v8 upgrade', () {
    const v7Ddl = [
      'CREATE TABLE settings (key TEXT NOT NULL, value_json TEXT NOT NULL, '
          'updated_at TEXT NOT NULL, PRIMARY KEY (key))',
      'CREATE TABLE migration_state (key TEXT NOT NULL, value TEXT NOT NULL, '
          'PRIMARY KEY (key))',
      "INSERT INTO settings VALUES ('axpert-dark', 'true', 0)",
      // Stand-ins so the v9 column additions find their tables.
      'CREATE TABLE products (id TEXT PRIMARY KEY)',
      'CREATE TABLE held_bills (id TEXT PRIMARY KEY)',
      'CREATE TABLE sales (id TEXT PRIMARY KEY)',
      'CREATE TABLE sale_lines (id TEXT PRIMARY KEY)',
    ];

    void seedV7(dynamic database, {String extra = ''}) {
      for (final sql in v7Ddl) {
        database.execute(sql);
      }
      if (extra.isNotEmpty) database.execute(extra);
      database.execute('PRAGMA user_version = 7');
    }

    test('adds current_cart and preserves data', () async {
      final database = AxpertDatabase(
        NativeDatabase.memory(setup: (db) => seedV7(db)),
      );
      addTearDown(database.close);

      final columns = await database
          .customSelect('PRAGMA table_info(current_cart)')
          .get();
      final settings = await database
          .customSelect('SELECT key FROM settings')
          .getSingle();
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();

      expect(columns.map((c) => c.read<String>('name')).toList(), [
        'id',
        'cart_json',
        'updated_at',
      ]);
      expect(settings.read<String>('key'), 'axpert-dark');
      expect(version.read<int>('user_version'), 11);
    });

    test('only one row (id 1) is allowed', () async {
      final database = AxpertDatabase(
        NativeDatabase.memory(setup: (db) => seedV7(db)),
      );
      addTearDown(database.close);

      await database.customStatement(
        "INSERT INTO current_cart (cart_json, updated_at) VALUES ('{}', 0)",
      );
      await expectLater(
        database.customStatement(
          "INSERT INTO current_cart (id, cart_json, updated_at) "
          "VALUES (2, '{}', 0)",
        ),
        throwsA(anything),
      );
      await expectLater(
        database.customStatement(
          "INSERT INTO current_cart (cart_json, updated_at) VALUES ('{}', 0)",
        ),
        throwsA(anything),
      );
    });

    test('failed upgrade leaves v7 data and user_version intact', () async {
      dynamic raw;
      final database = AxpertDatabase(
        NativeDatabase.memory(
          setup: (db) {
            raw = db;
            seedV7(db, extra: 'CREATE INDEX current_cart ON settings (key)');
          },
        ),
      );
      addTearDown(() async {
        try {
          await database.close();
        } on Object {
          // The migration failed on purpose; closing may fail too.
        }
      });

      await expectLater(
        database.customSelect('SELECT 1').getSingle(),
        throwsA(anything),
      );

      expect(
        raw.select('SELECT key FROM settings').single['key'],
        'axpert-dark',
      );
      expect(raw.select('PRAGMA user_version').single['user_version'], 7);
    });
  });
}
