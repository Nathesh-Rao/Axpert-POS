import 'dart:convert';

import '../../constants/storage_keys.dart';
import '../../services/storage/local_store.dart';
import '../../../modules/shell/models/app_settings.dart';
import '../axpert_database.dart';
import 'fnv1a.dart';

/// Marker row key in `migration_state`: the LocalStore to Drift copy of the
/// settings finished at least once.
const String settingsCopyMarkerKey = 'settings_copy_v1';

enum SettingsCopyResult { alreadyCopied, copied, recopied }

class SettingsMigrationException implements Exception {
  const SettingsMigrationException(this.message);

  final String message;

  @override
  String toString() => 'SettingsMigrationException: $message';
}

/// One-way copy of the 5 settings keys from [LocalStore] into Drift.
///
/// LocalStore is only read, except that the stale key is removed after a
/// verified re-copy. The marker means "copy completed" (count, copied_at);
/// its checksum is the copy-time read-back value and is never compared with
/// live rows later, since saves change them.
class SettingsMigrator {
  SettingsMigrator({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  /// Copies when there is no marker, or when the stale key is set (a session
  /// did not write to Drift). Throws [SettingsMigrationException] (or the
  /// parse error of a bad stored value) and leaves Drift unchanged on failure.
  Future<SettingsCopyResult> ensureCopied(
    AxpertDatabase db,
    LocalStore store,
  ) async {
    final stale = await store.has(StorageKeys.settingsDriftStale);
    final marker = await (db.select(
      db.migrationStateEntries,
    )..where((t) => t.key.equals(settingsCopyMarkerKey))).getSingleOrNull();
    if (marker != null && !stale) return SettingsCopyResult.alreadyCopied;

    final settings = await _readValidated(store);
    final expected = _canonicalRows(settings);
    final expectedChecksum = _checksum(expected);

    await db.durableTransaction(() async {
      final now = _now().toUtc().toIso8601String();
      await db.delete(db.settingsEntries).go();
      for (final entry in expected.entries) {
        await db
            .into(db.settingsEntries)
            .insert(
              SettingsEntriesCompanion.insert(
                key: entry.key,
                valueJson: entry.value,
                updatedAt: now,
              ),
            );
      }
      // Read-back verification (rolls the whole copy back when it fails).
      final rows = await db.select(db.settingsEntries).get();
      final actual = {for (final row in rows) row.key: row.valueJson};
      final readBack = AppSettings.fromJson({
        for (final e in actual.entries) e.key: jsonDecode(e.value),
      });
      if (actual.length != expected.length ||
          _checksum(actual) != expectedChecksum ||
          readBack != settings) {
        throw const SettingsMigrationException('read-back verification failed');
      }
      await db
          .into(db.migrationStateEntries)
          .insertOnConflictUpdate(
            MigrationStateEntriesCompanion.insert(
              key: settingsCopyMarkerKey,
              value: jsonEncode({
                'count': actual.length,
                'checksum': expectedChecksum,
                'copied_at': now,
              }),
            ),
          );
    });

    if (stale) await store.remove(StorageKeys.settingsDriftStale);
    return stale || marker != null
        ? SettingsCopyResult.recopied
        : SettingsCopyResult.copied;
  }

  /// Raw keys parsed with the existing [AppSettings.fromJson]; a wrong-typed
  /// value throws exactly as the Mock repository does today.
  Future<AppSettings> _readValidated(LocalStore store) async {
    final raw = <String, dynamic>{};
    for (final key in AppSettings.defaults.toJson().keys) {
      if (await store.has(key)) raw[key] = await store.read(key);
    }
    return AppSettings.fromJson(raw);
  }

  Map<String, String> _canonicalRows(AppSettings settings) => {
    for (final e in settings.toJson().entries) e.key: jsonEncode(e.value),
  };

  String _checksum(Map<String, String> rows) {
    final keys = rows.keys.toList()..sort();
    return fnv1a32Hex(keys.map((k) => '$k=${rows[k]}').join('\n'));
  }
}
