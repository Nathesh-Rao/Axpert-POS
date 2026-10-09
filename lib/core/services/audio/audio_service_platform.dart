// `createPlatformAudioService()`: Web Audio on the web, the system alert
// sound everywhere else (KG-181).
export 'audio_service_io.dart'
    if (dart.library.js_interop) 'audio_service_web.dart';
