import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/migration/fnv1a.dart';
import 'package:pos_application/core/database/migration/settings_migrator.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';

void main() {
  late AxpertDatabase db;
  late InMemoryLocalStore store;
  final migrator = SettingsMigrator(now: () => DateTime.utc(2026, 10, 12));

  setUp(() {
    db = AxpertDatabase(NativeDatabase.memory());
    store = InMemoryLocalStore();
  });
  tearDown(() => db.close());

  Future<Map<String, Object?>> driftRows() async => {
    for (final r in await db.select(db.settingsEntries).get())
      r.key: jsonDecode(r.valueJson),
  };

  Future<Map<String, Object?>> storeSnapshot() async => {
    for (final k in [
      StorageKeys.store,
      StorageKeys.dark,
      StorageKeys.beep,
      StorageKeys.counter,
      StorageKeys.settingsDriftStale,
    ])
      if (await store.has(k)) k: await store.read(k),
  };

  test('fnv1a32 known vectors', () {
    expect(fnv1a32Hex(''), '811c9dc5');
    expect(fnv1a32Hex('a'), 'e40c292c');
    expect(fnv1a32Hex('foobar'), 'bf9cf968');
  });

  test('copies the 6 keys with a marker, LocalStore untouched', () async {
    await store.write(StorageKeys.store, 'SHOP');
    await store.write(StorageKeys.dark, true);
    await store.write(StorageKeys.counter, 'C9');
    final before = await storeSnapshot();

    expect(await migrator.ensureCopied(db, store), SettingsCopyResult.copied);

    expect(await driftRows(), {
      StorageKeys.store: 'SHOP',
      StorageKeys.dark: true,
      StorageKeys.beep: true,
      StorageKeys.counter: 'C9',
      StorageKeys.printPaperMm: 80,
      StorageKeys.productsPanelOpen: false,
    });
    final marker = await db.select(db.migrationStateEntries).getSingle();
    expect(marker.key, settingsCopyMarkerKey);
    final json = jsonDecode(marker.value) as Map<String, dynamic>;
    expect(json['count'], 6);
    expect(json['checksum'], hasLength(8));
    expect(json['copied_at'], '2026-10-12T00:00:00.000Z');
    expect(await storeSnapshot(), before);
  });

  test('second run is a no-op and live rows are not re-verified', () async {
    await migrator.ensureCopied(db, store);
    await (db.update(db.settingsEntries)
          ..where((t) => t.key.equals(StorageKeys.counter)))
        .write(const SettingsEntriesCompanion(valueJson: Value('"C9"')));

    expect(
      await migrator.ensureCopied(db, store),
      SettingsCopyResult.alreadyCopied,
    );
    expect((await driftRows())[StorageKeys.counter], 'C9');
  });

  test('wrong-typed stored value fails and writes nothing', () async {
    await store.write(StorageKeys.dark, 'yes');

    await expectLater(migrator.ensureCopied(db, store), throwsA(isA<Error>()));

    expect(await driftRows(), isEmpty);
    expect(await db.select(db.migrationStateEntries).get(), isEmpty);
    expect(await store.read(StorageKeys.dark), 'yes');
  });

  test('verification failure rolls everything back', () async {
    // A trigger that rewrites inserted values makes the read-back differ.
    await db.customStatement(
      'CREATE TRIGGER corrupt AFTER INSERT ON settings BEGIN '
      "UPDATE settings SET value_json = '\"x\"' WHERE key = NEW.key; END",
    );

    await expectLater(migrator.ensureCopied(db, store), throwsA(isA<Object>()));

    expect(await driftRows(), isEmpty);
    expect(await db.select(db.migrationStateEntries).get(), isEmpty);
  });

  test('stale key forces a replace-copy, then is cleared', () async {
    await migrator.ensureCopied(db, store);
    await store.write(StorageKeys.counter, 'C7');
    await store.write(StorageKeys.settingsDriftStale, true);

    expect(await migrator.ensureCopied(db, store), SettingsCopyResult.recopied);

    expect((await driftRows())[StorageKeys.counter], 'C7');
    expect(await store.has(StorageKeys.settingsDriftStale), isFalse);
    expect(await db.select(db.migrationStateEntries).get(), hasLength(1));
  });

  test(
    'failed re-copy keeps old Drift rows, LocalStore authoritative',
    () async {
      await migrator.ensureCopied(db, store);
      await store.write(StorageKeys.beep, 'loud');
      await store.write(StorageKeys.settingsDriftStale, true);

      await expectLater(
        migrator.ensureCopied(db, store),
        throwsA(isA<Error>()),
      );

      expect(await store.has(StorageKeys.settingsDriftStale), isTrue);
      expect((await driftRows())[StorageKeys.beep], true);
    },
  );
}
