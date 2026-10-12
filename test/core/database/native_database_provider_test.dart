import 'package:pos_application/core/database/database_config.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/database/drift_device_context_store.dart';
import 'package:pos_application/core/device/device_context.dart';
import 'package:pos_application/core/database/native_database_provider.dart';
import 'package:drift/native.dart';
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
      expect(first.schemaVersion, 2);
      expect(first.allTables, hasLength(1));
      expect(first.allTables.single.actualTableName, 'device_context_entries');
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

    expect(database.schemaVersion, 2);
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
}
