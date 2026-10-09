import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'audio_service.dart';

AudioService createPlatformAudioService() => WebAudioService();

@JS('AudioContext')
extension type _AudioContext._(JSObject _) implements JSObject {
  external factory _AudioContext();
  external String get state;
  external double get currentTime;
  external JSObject get destination;
  external JSPromise<JSAny?> resume();
  external _Oscillator createOscillator();
  external _Gain createGain();
}

extension type _Param._(JSObject _) implements JSObject {
  external set value(double value);
}

extension type _Oscillator._(JSObject _) implements JSObject {
  external set type(String value);
  external _Param get frequency;
  external void connect(JSObject node);
  external void start();
  external void stop(double when);
}

extension type _Gain._(JSObject _) implements JSObject {
  external _Param get gain;
  external void connect(JSObject node);
}

extension type _Window._(JSObject _) implements JSObject {
  external void addEventListener(String type, JSFunction callback, JSObject o);
}

@JS('window')
external _Window get _window;

/// The prototype's `playBeep()` with Web Audio: sine, 1100 Hz, gain 0.04,
/// 80 ms. Browsers keep an AudioContext suspended until a user gesture, so
/// the context is created lazily and resumed on the first pointer or key
/// event; a beep before that is silent (React's try/catch does the same).
class WebAudioService implements AudioService {
  WebAudioService() {
    final options = JSObject()..setProperty('once'.toJS, true.toJS);
    final unlock = ((JSAny _) => _unlock()).toJS;
    _window.addEventListener('pointerdown', unlock, options);
    _window.addEventListener('keydown', unlock, options);
  }

  _AudioContext? _context;

  _AudioContext? _ensure() {
    try {
      return _context ??= _AudioContext();
    } on Object {
      return null;
    }
  }

  void _unlock() {
    final context = _ensure();
    if (context != null && context.state == 'suspended') {
      context.resume().toDart.then<void>((_) {}, onError: (Object _) {});
    }
  }

  @override
  void beep() {
    final context = _ensure();
    if (context == null) return;
    if (context.state == 'running') {
      _play(context);
      return;
    }
    // Still suspended (the unlock promise has not resolved yet): play once
    // it does; before any gesture the promise rejects and nothing sounds.
    context.resume().toDart.then<void>(
      (_) => _play(context),
      onError: (Object _) {},
    );
  }

  void _play(_AudioContext context) {
    final oscillator = context.createOscillator();
    final gain = context.createGain();
    oscillator.type = 'sine';
    oscillator.frequency.value = _frequencyHz;
    gain.gain.value = _gainLevel;
    oscillator.connect(gain);
    gain.connect(context.destination);
    final now = context.currentTime;
    oscillator.start();
    oscillator.stop(now + _durationSeconds);
  }
}

const double _frequencyHz = 1100;
const double _gainLevel = 0.04;
const double _durationSeconds = 0.08;
