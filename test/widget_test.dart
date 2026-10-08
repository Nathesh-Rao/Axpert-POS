import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/main.dart';

import 'support/test_app.dart';

void main() {
  useTestApp();

  testWidgets('app boots on POS', (tester) async {
    final binding = await bootInWidgetTest(tester);
    await tester.pumpWidget(testApp(binding));
    await tester.pumpAndSettle();
    expect(find.byType(PosApp), findsOneWidget);
    expect(find.text('POS'), findsOneWidget);
  });
}
