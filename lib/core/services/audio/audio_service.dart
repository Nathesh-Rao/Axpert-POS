/// Plays sounds. Plain Dart (no GetX): the only sound the prototype has is
/// the short success beep (`playBeep()`: 1100 Hz sine, gain 0.04, 80 ms).
abstract interface class AudioService {
  /// The success beep. Never throws; silent when the platform cannot play.
  void beep();
}

/// Test double (and the fallback when no audio exists): counts beeps.
class RecordingAudioService implements AudioService {
  /// Number of beeps requested.
  int beeps = 0;

  @override
  void beep() => beeps++;
}
