import 'audio/audio_service.dart';

/// Scan beep: the prototype plays a short tone after a successful add to the
/// cart when the beep setting is on (`playBeep()` in `add()`).
abstract interface class BeepService {
  void play();
}

/// Gates [AudioService.beep] behind the persisted beep setting.
class SettingBeepService implements BeepService {
  SettingBeepService(this._enabled, this._audio);

  final bool Function() _enabled;
  final AudioService _audio;

  @override
  void play() {
    if (!_enabled()) return;
    _audio.beep();
  }
}
