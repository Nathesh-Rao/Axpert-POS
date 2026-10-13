import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/core/services/storage/local_store.dart';
import 'package:pos_application/modules/shell/models/app_settings.dart';
import 'package:pos_application/modules/shell/repository/drift_settings_repository.dart';
import 'package:pos_application/modules/shell/repository/mock_settings_repository.dart';
import 'package:pos_application/modules/shell/repository/settings_repository.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  final AxpertDatabase db;

  @override
  Future<AxpertDatabase> open() async => db;

  @override
  Future<void> close() async {}
}

/// One backend under test: [create] builds a repository over the shared
/// [store] (a new call is a "restart" on the same persisted data).
class _Backend {
  _Backend(this.create, [this.dispose]);

  final SettingsRepository Function(LocalStore store) create;
  final Future<void> Function()? dispose;
}

_Backend _mock() => _Backend(MockSettingsRepository.new);

_Backend _drift() {
  final db = AxpertDatabase(NativeDatabase.memory());
  return _Backend(
    (store) => DriftSettingsRepository(
      provider: _Provider(db),
      store: store,
      diagnostics: StartupDiagnostics(),
    ),
    db.close,
  );
}

void main() {
  setUp(() => MockDelay.provider = () => Duration.zero);

  final backends = <String, _Backend Function()>{
    'Mock': _mock,
    'Drift (in-memory)': _drift,
  };
  for (final entry in backends.entries) {
    final make = entry.value;
    group('SettingsRepository contract: ${entry.key}', () {
      late _Backend backend;
      late InMemoryLocalStore store;

      setUp(() {
        backend = make();
        store = InMemoryLocalStore();
      });
      tearDown(() async => backend.dispose?.call());

      test('first load returns the prototype defaults', () async {
        expect(await backend.create(store).load(), AppSettings.defaults);
      });

      test('save then load on a new instance round-trips', () async {
        const next = AppSettings(
          store: 'MAISON GALAXY - MARINA',
          dark: true,
          beep: false,
          counter: 'C9',
        );
        final first = backend.create(store);
        await first.load();
        await first.save(next);

        expect(await backend.create(store).load(), next);
      });

      test('a later save overwrites an earlier one', () async {
        final repo = backend.create(store);
        final loaded = await repo.load();
        await repo.save(loaded.copyWith(counter: 'C1'));
        await repo.save(loaded.copyWith(counter: 'C2', dark: true));

        final again = await backend.create(store).load();
        expect(again.counter, 'C2');
        expect(again.dark, isTrue);
      });

      test('existing stored values win, missing keys use defaults', () async {
        await store.write(StorageKeys.store, 'SHOP');
        await store.write(StorageKeys.beep, false);

        final loaded = await backend.create(store).load();

        expect(
          loaded,
          AppSettings.defaults.copyWith(store: 'SHOP', beep: false),
        );
      });

      test('a stored null falls back to the default', () async {
        await store.write(StorageKeys.counter, null);

        expect((await backend.create(store).load()).counter, '');
      });

      // Current behavior (kept, not fixed): AppSettings.fromJson casts each
      // value, so a wrong-typed stored value makes load() throw a TypeError.
      test('a wrong-typed stored value makes load throw', () async {
        await store.write(StorageKeys.dark, 'yes');

        await expectLater(
          backend.create(store).load(),
          throwsA(isA<TypeError>()),
        );
      });

      test('a leftover rate key of an older version is ignored', () async {
        await store.write('axpert-rate', 7000);

        expect(await backend.create(store).load(), AppSettings.defaults);
      });
    });
  }
}
