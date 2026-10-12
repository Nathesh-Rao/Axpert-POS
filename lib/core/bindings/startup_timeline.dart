import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Start-up phase timings (measurement only, no behavior change).
///
/// Off unless the app is built with `--dart-define=STARTUP_TIMELINE=true`; when
/// off every method returns at once and no zone is created. When on, the
/// phases are collected in memory and printed once as a `[startup] {json}`
/// console line after the first frame is rasterized (read by
/// `tool/web_check/startup_check.mjs`).
///
/// [measure] runs its body in a zone that carries the phase name, so
/// `MockDelay.wait` can attribute the simulated latency to the phase that
/// waited (no change in the mock repositories).
abstract final class StartupTimeline {
  static const bool enabled = bool.fromEnvironment('STARTUP_TIMELINE');

  static const Symbol _phaseKey = #startupTimelinePhase;

  static final Stopwatch _clock = Stopwatch();
  static int _epochAtStartMs = 0;
  static final List<Map<String, Object?>> _phases = <Map<String, Object?>>[];
  static final Map<String, int> _mockDelayMs = <String, int>{};

  static void _ensureStarted() {
    if (_clock.isRunning) return;
    _epochAtStartMs = DateTime.now().millisecondsSinceEpoch;
    _clock.start();
  }

  /// A point in time (`main start`, `runApp called`, `first frame`).
  static void mark(String name) {
    if (!enabled) return;
    _ensureStarted();
    _phases.add(<String, Object?>{'name': name, 'at': _nowUs()});
  }

  /// Times [body] as phase [name] (start offset and duration).
  static Future<T> measure<T>(String name, Future<T> Function() body) {
    if (!enabled) return body();
    _ensureStarted();
    final startUs = _nowUs();
    return runZoned(() async {
      try {
        return await body();
      } finally {
        _phases.add(<String, Object?>{
          'name': name,
          'at': startUs,
          'dur': _nowUs() - startUs,
        });
      }
    }, zoneValues: <Symbol, Object?>{_phaseKey: name});
  }

  /// Synchronous variant of [measure].
  static T measureSync<T>(String name, T Function() body) {
    if (!enabled) return body();
    _ensureStarted();
    final startUs = _nowUs();
    try {
      return body();
    } finally {
      _phases.add(<String, Object?>{
        'name': name,
        'at': startUs,
        'dur': _nowUs() - startUs,
      });
    }
  }

  /// Called by `MockDelay.wait`: adds [delay] to the phase running it.
  static void recordMockDelay(Duration delay) {
    if (!enabled) return;
    final phase = Zone.current[_phaseKey];
    if (phase is! String) return;
    _mockDelayMs[phase] = (_mockDelayMs[phase] ?? 0) + delay.inMilliseconds;
  }

  /// Prints the collected phases once.
  static void report() {
    if (!enabled) return;
    debugPrint(
      '[startup] ${jsonEncode(<String, Object?>{'epoch_at_start_ms': _epochAtStartMs, 'phases': _phases, 'mock_delay_ms': _mockDelayMs})}',
    );
  }

  static int _nowUs() => _clock.elapsedMicroseconds;
}
