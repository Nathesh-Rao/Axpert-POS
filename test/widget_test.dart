import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';
import 'package:pos_application/main.dart';

void main() {
  setUpAll(() => AppTypography.useBundledFonts = true);
  tearDownAll(() => AppTypography.useBundledFonts = false);

  testWidgets('placeholder app boots', (tester) async {
    await tester.pumpWidget(const PosApp());
    expect(find.byType(PosApp), findsOneWidget);
  });
}
