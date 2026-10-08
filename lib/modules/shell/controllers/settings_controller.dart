import 'package:get/get.dart';

import '../models/app_settings.dart';
import '../repository/settings_repository.dart';

/// Permanent controller for the persisted shell settings (store, dark, beep,
/// counter, forex rate). State changes first, persistence follows.
class SettingsController extends GetxController {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  final Rx<AppSettings> settings = AppSettings.defaults.obs;

  bool get dark => settings.value.dark;

  Future<void> load() async {
    settings.value = await _repository.load();
  }

  Future<void> _update(AppSettings next) async {
    settings.value = next;
    await _repository.save(next);
  }

  Future<void> setDark(bool value) =>
      _update(settings.value.copyWith(dark: value));

  Future<void> toggleDark() => setDark(!dark);

  Future<void> setBeep(bool value) =>
      _update(settings.value.copyWith(beep: value));

  Future<void> setStore(String value) =>
      _update(settings.value.copyWith(store: value));

  Future<void> setCounter(String value) =>
      _update(settings.value.copyWith(counter: value));

  Future<void> setRateMilli(int value) =>
      _update(settings.value.copyWith(rateMilli: value));
}
