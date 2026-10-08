import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/theme/app_theme.dart';
import 'package:pos_application/shared/widgets/hold_to_repeat_button.dart';

Future<int Function()> _pump(WidgetTester tester) async {
  var count = 0;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Center(
        child: HoldToRepeatButton(
          tooltip: 'hold',
          borderRadius: 0,
          onAction: () => count++,
          builder: (context, hovered) =>
              const SizedBox(width: 40, height: 40, child: Text('x')),
        ),
      ),
    ),
  );
  return () => count;
}

void main() {
  testWidgets('a click runs the action once', (tester) async {
    final count = await _pump(tester);
    await tester.tap(find.text('x'));
    await tester.pump();
    expect(count(), 1);
    await tester.pump(const Duration(seconds: 1));
    expect(count(), 1);
  });

  testWidgets('hold: nothing before 500 ms, then 1, then every 140 ms', (
    tester,
  ) async {
    final count = await _pump(tester);
    final gesture = await tester.startGesture(tester.getCenter(find.text('x')));
    await tester.pump(const Duration(milliseconds: 499));
    expect(count(), 0);
    await tester.pump(const Duration(milliseconds: 2)); // 501 ms
    expect(count(), 1);
    await tester.pump(const Duration(milliseconds: 138)); // 639 ms
    expect(count(), 1);
    await tester.pump(const Duration(milliseconds: 2)); // 641 ms
    expect(count(), 2);
    await tester.pump(const Duration(milliseconds: 280)); // 921 ms
    expect(count(), 4);
    await gesture.up();
    await tester.pump();
    // The click that ends a hold does not run the action again.
    expect(count(), 4);
    await tester.pump(const Duration(seconds: 1));
    expect(count(), 4);
  });

  testWidgets('releasing before 500 ms stops the timers', (tester) async {
    final count = await _pump(tester);
    final gesture = await tester.startGesture(tester.getCenter(find.text('x')));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pump();
    expect(count(), 1); // the click
    await tester.pump(const Duration(seconds: 2));
    expect(count(), 1);
  });
}
