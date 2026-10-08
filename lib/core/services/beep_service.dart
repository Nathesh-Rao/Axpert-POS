/// Scan beep (hardware/audio later). The prototype plays a short 1100 Hz tone
/// when the beep setting is on; the Flutter stub does nothing audible yet.
abstract interface class BeepService {
  void play();
}

class NoopBeepService implements BeepService {
  NoopBeepService(this._enabled);

  final bool Function() _enabled;

  /// Counts accepted beeps (tests).
  int played = 0;

  @override
  void play() {
    if (!_enabled()) return;
    played++;
  }
}
