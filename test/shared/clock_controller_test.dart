// ClockController: attach never writes `now` (it runs inside widget builds and
// controller creation); only the timer ticks do. VM test.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/shared/controllers/clock_controller.dart';

void main() {
  testWidgets('attach does not notify; ticks do; detach stops them', (
    tester,
  ) async {
    var real = DateTime(2026, 10, 9, 10, 0, 0);
    final clock = ClockController(now: () => real);
    final seen = <DateTime>[];
    final worker = ever<DateTime>(clock.now, seen.add);

    real = DateTime(2026, 10, 9, 10, 0, 30);
    clock.attach();
    expect(seen, isEmpty, reason: 'attach must not write now');
    expect(clock.now.value, DateTime(2026, 10, 9, 10, 0, 0));
    expect(clock.current, DateTime(2026, 10, 9, 10, 0, 30));

    Future<void> tick() async {
      real = real.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }

    await tick();
    expect(seen.length, 1);
    await tick();
    await tick();
    expect(seen.length, 3);

    clock.attach();
    clock.detach();
    await tick();
    expect(seen.length, 4, reason: 'one attachment left: still ticking');
    clock.detach();
    await tick();
    await tick();
    expect(seen.length, 4, reason: 'no attachment: no timer');
    worker.dispose();
    clock.onClose();
  });
}
