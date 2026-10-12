import 'dart:math';

import '../bindings/startup_timeline.dart';

/// Simulated latency of the mock repositories (200 to 500 ms, DEC-042).
/// Tests replace [provider] with a zero delay.
abstract final class MockDelay {
  static final Random _random = Random();

  static Duration Function() provider = () =>
      Duration(milliseconds: 200 + _random.nextInt(301));

  static Future<void> wait() {
    final delay = provider();
    StartupTimeline.recordMockDelay(delay);
    return Future<void>.delayed(delay);
  }
}
