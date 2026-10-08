import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/main.dart';

void main() {
  testWidgets('placeholder app boots', (tester) async {
    await tester.pumpWidget(const PosApp());
    expect(find.byType(PosApp), findsOneWidget);
  });
}
