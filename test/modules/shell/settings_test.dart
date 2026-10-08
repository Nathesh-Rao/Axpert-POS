import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/modules/shell/models/app_settings.dart';
import 'package:pos_application/modules/shell/repository/mock_settings_repository.dart';

import '../../support/test_app.dart';

void main() {
  useTestApp();

  test('first run seeds the prototype defaults into the store', () async {
    final store = InMemoryLocalStore();
    await bootTestApp(store: store);
    expect(Get.find<SettingsController>().settings.value, AppSettings.defaults);
    for (final key in settingsStorageKeys) {
      expect(await store.has(key), isTrue, reason: key);
    }
    expect(await store.read(StorageKeys.rate), 8561);
  });

  test('changes persist and survive a new controller (restart)', () async {
    final store = InMemoryLocalStore();
    await bootTestApp(store: store);
    final c = Get.find<SettingsController>();
    await c.setDark(true);
    await c.setStore('MAISON GALAXY - MARINA');
    await c.setBeep(false);
    await c.setRateMilli(9000);

    await bootTestApp(store: store); // Get.reset + new instances
    final again = Get.find<SettingsController>().settings.value;
    expect(again.dark, isTrue);
    expect(again.beep, isFalse);
    expect(again.store, 'MAISON GALAXY - MARINA');
    expect(again.rateMilli, 9000);
    expect(again.counter, 'C3');
  });

  test('toggleDark flips the flag', () async {
    await bootTestApp();
    final c = Get.find<SettingsController>();
    expect(c.dark, isFalse);
    await c.toggleDark();
    expect(c.dark, isTrue);
  });

  test('model JSON round trip', () {
    const s = AppSettings(
      store: 'x',
      dark: true,
      beep: false,
      counter: 'C9',
      rateMilli: 1,
    );
    expect(AppSettings.fromJson(s.toJson()), s);
    expect(AppSettings.fromJson(<String, dynamic>{}), AppSettings.defaults);
  });
}
