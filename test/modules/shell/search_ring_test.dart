import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

/// React draws the focus ring on the input, and `input{height:100%}` makes the
/// input fill the field, so the ring is as tall as the field's content.
void main() {
  useTestApp();

  for (final size in const <Size>[Size(1868.44, 1034.67), Size(1100, 700)]) {
    testWidgets('search inputs fill their field at ${size.width.toInt()}', (
      tester,
    ) async {
      useLogicalViewport(tester, size);
      final binding = await bootInWidgetTest(tester);
      await tester.pumpWidget(testApp(binding));
      await tester.pumpAndSettle();
      final m = AppMetrics(size);
      final inputs = find.byType(TextField);
      // Field boxes have a 1 px border.
      expect(tester.getSize(inputs.at(0)).height, m.searchHeight - 2);
      expect(tester.getSize(inputs.at(1)).height, m.fieldHeight - 2);
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
