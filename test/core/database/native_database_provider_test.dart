import 'package:pos_application/core/database/database_config.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/database/drift_device_context_store.dart';
import 'package:pos_application/core/device/device_context.dart';
import 'package:pos_application/core/database/native_database_provider.dart';
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
      expect(first.schemaVersion, 5);
      expect(first.allTables.map((table) => table.actualTableName).toSet(), {
        'device_context_entries',
        'settings',
        'migration_state',
        'customers',
        'held_bills',
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

    expect(database.schemaVersion, 5);
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
      expect(version.read<int>('user_version'), 5);
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
      "INSERT INTO settings VALUES ('axpert-dark', 'true', 'x')",
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
      expect(version.read<int>('user_version'), 5);
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
      "INSERT INTO settings VALUES ('axpert-dark', 'true', 'x')",
      "INSERT INTO customers (id, legacy_id, position, name, phone, email, "
          "member_no, points, created_at, updated_at) VALUES "
          "('u1', 'walk', 0, 'Walk-in', '', '', '', 0, 'x', 'x')",
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
      expect(version.read<int>('user_version'), 5);
      expect(columns.map((c) => c.read<String>('name')).toList(), [
        'id',
        'ref',
        'position',
        'held_at',
        'cart_json',
        'created_at',
        'updated_at',
        'deleted_at',
      ]);
    });

    test('a database already at v5 opens unchanged', () async {
      final database = AxpertDatabase(
        NativeDatabase.memory(setup: (db) => seedV4(db)),
      );
      addTearDown(database.close);
      await database.customSelect('SELECT 1').getSingle();
      await database.customStatement(
        "INSERT INTO held_bills VALUES ('u', 'H1', 0, 't', '{}', 'x', 'x', NULL)",
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
}
