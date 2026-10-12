import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/shell/models/app_settings.dart';
import 'package:pos_application/modules/shell/repository/drift_settings_repository.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  AxpertDatabase? db;

  @override
  Future<AxpertDatabase> open() async =>
      db ?? (throw StateError('database unavailable'));

  @override
  Future<void> close() async {}
}

void main() {
  late AxpertDatabase db;
  late InMemoryLocalStore store;
  late StartupDiagnostics diagnostics;

  setUp(() {
    MockDelay.provider = () => Duration.zero;
    db = AxpertDatabase(NativeDatabase.memory());
    store = InMemoryLocalStore();
    diagnostics = StartupDiagnostics();
  });
  tearDown(() => db.close());

  DriftSettingsRepository repo(AxpertDatabase? database) =>
      DriftSettingsRepository(
        provider: _Provider(database),
        store: store,
        diagnostics: diagnostics,
      );

  Future<Object?> driftValue(String key) async {
    final row = await (db.select(
      db.settingsEntries,
    )..where((t) => t.key.equals(key))).getSingle();
    return jsonDecode(row.valueJson);
  }

  test('first load copies LocalStore into Drift', () async {
    await store.write(StorageKeys.counter, 'C5');

    final loaded = await repo(db).load();

    expect(loaded, AppSettings.defaults.copyWith(counter: 'C5'));
    expect(await driftValue(StorageKeys.counter), 'C5');
    expect(await store.has(StorageKeys.settingsDriftStale), isFalse);
  });

  test('save writes Drift and dual-writes LocalStore', () async {
    final repository = repo(db);
    await repository.load();
    final next = AppSettings.defaults.copyWith(dark: true, rateMilli: 9100);

    await repository.save(next);

    expect(await driftValue(StorageKeys.dark), true);
    expect(await driftValue(StorageKeys.rate), 9100);
    expect(await store.read(StorageKeys.dark), true);
    expect(await store.read(StorageKeys.rate), 9100);
    expect(await repo(db).load(), next);
  });

  test('fallback session marks stale; restart re-copies', () async {
    await repo(db).load();
    final failing = repo(null);

    final loaded = await failing.load();
    await failing.save(loaded.copyWith(counter: 'C8'));

    expect(loaded, AppSettings.defaults);
    expect(diagnostics.hasFailures, isTrue);
    expect(await store.read(StorageKeys.settingsDriftStale), true);
    expect(await driftValue(StorageKeys.counter), 'C3');

    final restarted = await repo(db).load();

    expect(restarted.counter, 'C8');
    expect(await driftValue(StorageKeys.counter), 'C8');
    expect(await store.has(StorageKeys.settingsDriftStale), isFalse);
  });

  test('localStore backend session, then switch back to Drift', () async {
    await repo(db).load();
    final rollback = LocalStoreSettingsRepository(store);

    final loaded = await rollback.load();
    await rollback.save(loaded.copyWith(store: 'OTHER', beep: false));

    expect(await store.read(StorageKeys.settingsDriftStale), true);
    expect(await driftValue(StorageKeys.store), 'MAISON GALAXY - OZONE');

    final back = await repo(db).load();

    expect(back.store, 'OTHER');
    expect(back.beep, isFalse);
    expect(await driftValue(StorageKeys.store), 'OTHER');
    expect(await store.has(StorageKeys.settingsDriftStale), isFalse);
  });

  test('failed re-copy keeps LocalStore authoritative, key stays', () async {
    await repo(db).load();
    await store.write(StorageKeys.settingsDriftStale, true);
    await store.write(StorageKeys.counter, 42);

    await expectLater(repo(db).load(), throwsA(isA<Error>()));

    expect(await store.has(StorageKeys.settingsDriftStale), isTrue);
    expect(await store.read(StorageKeys.counter), 42);
    expect(await driftValue(StorageKeys.counter), 'C3');
  });

  test('Drift save failure falls back to LocalStore and marks stale', () async {
    final repository = repo(db);
    final loaded = await repository.load();
    await db.customStatement('DROP TABLE settings');

    await repository.save(loaded.copyWith(counter: 'C1'));

    expect(await store.read(StorageKeys.counter), 'C1');
    expect(await store.read(StorageKeys.settingsDriftStale), true);
    expect(diagnostics.hasFailures, isTrue);
  });
}
