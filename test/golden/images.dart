import 'package:flutter_test/flutter_test.dart';

/// Product PNGs decode on real async time, outside the fake-async zone: give
/// them a moment and pump, so goldens draw the pictures.
Future<void> settleImages(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 500)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}
