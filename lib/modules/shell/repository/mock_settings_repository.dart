import '../../../core/constants/storage_keys.dart';
import '../../../core/mock/mock_delay.dart';
import '../../../core/services/storage/local_store.dart';
import '../../../core/services/storage/local_store_seeder.dart';
import '../models/app_settings.dart';
import 'settings_repository.dart';

/// Mock repository: persists through [LocalStore] after a simulated delay and
/// seeds the prototype defaults on first run.
class MockSettingsRepository implements SettingsRepository {
  MockSettingsRepository(this._store);

  final LocalStore _store;

  @override
  Future<AppSettings> load() async {
    await MockDelay.wait();
    final seeds = AppSettings.defaults.toJson();
    final values = <String, dynamic>{};
    for (final key in seeds.keys) {
      values[key] = await LocalStoreSeeder.seedIfMissing(
        _store,
        key,
        seeds[key],
      );
    }
    return AppSettings.fromJson(values);
  }

  @override
  Future<void> save(AppSettings settings) async {
    await MockDelay.wait();
    final json = settings.toJson();
    for (final key in json.keys) {
      await _store.write(key, json[key]);
    }
  }
}

/// Keys owned by this repository (used by tests).
const List<String> settingsStorageKeys = <String>[
  StorageKeys.store,
  StorageKeys.dark,
  StorageKeys.beep,
  StorageKeys.counter,
  StorageKeys.rate,
];
