import 'dart:async';

import 'package:flutter/services.dart';

import 'audio_service.dart';

AudioService createPlatformAudioService() => const SystemSoundAudioService();

/// Desktop and mobile: the OS alert sound (`SystemSoundType.alert`), not the
/// prototype's 1100 Hz tone (KG-181).
class SystemSoundAudioService implements AudioService {
  const SystemSoundAudioService();

  @override
  void beep() => unawaited(SystemSound.play(SystemSoundType.alert));
}
