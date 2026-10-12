import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/bindings/startup_timeline.dart';
import 'package:pos_application/core/mock/mock_delay.dart';

void main() {
  test(
    'off by default: measure only runs the body, nothing is recorded',
    () async {
      expect(StartupTimeline.enabled, isFalse);
      StartupTimeline.mark('x');
      expect(await StartupTimeline.measure('a', () async => 7), 7);
      expect(StartupTimeline.measureSync('b', () => 8), 8);
      StartupTimeline.recordMockDelay(const Duration(seconds: 1));
      StartupTimeline.report();
    },
  );

  test('MockDelay.wait still waits for the provided delay', () async {
    final saved = MockDelay.provider;
    addTearDown(() => MockDelay.provider = saved);
    MockDelay.provider = () => const Duration(milliseconds: 20);
    final sw = Stopwatch()..start();
    await MockDelay.wait();
    expect(sw.elapsedMilliseconds, greaterThanOrEqualTo(15));
  });
}
