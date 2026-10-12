import 'dart:convert';

import '../../../core/bindings/startup_diagnostics.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/database/axpert_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/migration/settings_migrator.dart';
import '../../../core/services/storage/local_store.dart';
import '../models/app_settings.dart';
import 'mock_settings_repository.dart';
import 'settings_repository.dart';

/// Settings in Drift (source of truth), dual-written to [LocalStore] so the
/// rollback to the LocalStore backend loses nothing (DEC-125).
///
/// When Drift cannot be used (open, copy or write failure) the session falls
/// back to LocalStore and sets the stale key, so the next start re-copies
/// LocalStore into Drift before Drift is read again.
class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository({
    required DatabaseProvider provider,
    required LocalStore store,
    required StartupDiagnostics diagnostics,
    SettingsMigrator? migrator,
    DateTime Function()? now,
  }) : _provider = provider,
       _store = store,
       _diagnostics = diagnostics,
       _migrator = migrator ?? SettingsMigrator(now: now),
       _now = now ?? DateTime.now,
       _fallback = MockSettingsRepository(store);

  final DatabaseProvider _provider;
  final LocalStore _store;
  final StartupDiagnostics _diagnostics;
  final SettingsMigrator _migrator;
  final DateTime Function() _now;
  final MockSettingsRepository _fallback;

  /// Null until Drift loaded successfully, and again after a failure.
  AxpertDatabase? _db;

  @override
  Future<AppSettings> load() async {
    try {
      final db = await _provider.open();
      await _migrator.ensureCopied(db, _store);
      final settings = await _readRows(db);
      _db = db;
      return settings;
    } on Object catch (error, stackTrace) {
      await _degrade('settings load', error, stackTrace);
      return _fallback.load();
    }
  }

  @override
  Future<void> save(AppSettings settings) async {
    final db = _db;
    if (db == null) {
      await _markStale();
      return _fallback.save(settings);
    }
    final json = settings.toJson();
    try {
      final now = _now().toUtc().toIso8601String();
      await db.durableTransaction(() async {
        for (final entry in json.entries) {
          await db
              .into(db.settingsEntries)
              .insertOnConflictUpdate(
                SettingsEntriesCompanion.insert(
                  key: entry.key,
                  valueJson: jsonEncode(entry.value),
                  updatedAt: now,
                ),
              );
        }
      });
    } on Object catch (error, stackTrace) {
      await _degrade('settings save', error, stackTrace);
      return _fallback.save(settings);
    }
    try {
      for (final entry in json.entries) {
        await _store.write(entry.key, entry.value);
      }
    } on Object catch (error, stackTrace) {
      // Drift is already saved; only the rollback copy is behind.
      _diagnostics.record('settings dual-write', error, stackTrace);
    }
  }

  Future<AppSettings> _readRows(AxpertDatabase db) async {
    final rows = await db.select(db.settingsEntries).get();
    return AppSettings.fromJson({
      for (final row in rows) row.key: jsonDecode(row.valueJson),
    });
  }

  Future<void> _degrade(String stage, Object error, StackTrace stackTrace) {
    _db = null;
    _diagnostics.record(stage, error, stackTrace);
    return _markStale();
  }

  Future<void> _markStale() async {
    try {
      await _store.write(StorageKeys.settingsDriftStale, true);
    } on Object catch (error, stackTrace) {
      _diagnostics.record('settings stale marker', error, stackTrace);
    }
  }
}

/// The rollback backend: LocalStore only. Every session marks Drift stale, so
/// switching back to Drift re-copies first (DEC-125).
class LocalStoreSettingsRepository implements SettingsRepository {
  LocalStoreSettingsRepository(this._store)
    : _inner = MockSettingsRepository(_store);

  final LocalStore _store;
  final MockSettingsRepository _inner;

  @override
  Future<AppSettings> load() async {
    await _store.write(StorageKeys.settingsDriftStale, true);
    return _inner.load();
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _store.write(StorageKeys.settingsDriftStale, true);
    return _inner.save(settings);
  }
}
