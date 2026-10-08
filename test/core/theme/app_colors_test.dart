import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/theme/app_theme.dart';
import 'package:pos_application/core/theme/theme_x.dart';
import 'package:pos_application/core/theme/tokens/app_colors.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';

void main() {
  setUpAll(() => AppTypography.useBundledFonts = true);
  tearDownAll(() => AppTypography.useBundledFonts = false);

  test('copyWith replaces only the given field', () {
    const red = Color(0xFFFF0000);
    final c = AppColors.light.copyWith(card: red, productImageRadius: 9);
    expect(c.card, red);
    expect(c.productImageRadius, 9);
    expect(c.background, AppColors.light.background);
    expect(c.productImageMultiply, isTrue);
  });

  test('lerp reaches both ends and interpolates in between', () {
    final a = AppColors.light;
    final b = AppColors.dark;
    expect(a.lerp(b, 0).toMap(), a.toMap());
    expect(a.lerp(b, 1).toMap(), b.toMap());
    final mid = a.lerp(b, 0.5);
    expect(mid.background, Color.lerp(a.background, b.background, 0.5));
    expect(mid.productImageRadius, 2);
    expect(mid.quickActionHoverBrightness, closeTo(1.1, 1e-9));
    expect(a.lerp(b, 0.4).productImageMultiply, isTrue);
    expect(a.lerp(b, 0.6).productImageMultiply, isFalse);
    expect(a.lerp(null, 0.5), same(a));
  });

  test('dark mode behaviours follow the .dark rules', () {
    expect(AppColors.light.productImageMultiply, isTrue);
    expect(AppColors.dark.productImageMultiply, isFalse);
    expect(AppColors.dark.productImageRadius, 4);
    expect(AppColors.dark.quickActionHoverBrightness, 1.2);
  });

  Future<BuildContext> pumpWith(WidgetTester tester, ThemeData theme) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (c) {
            captured = c;
            return const SizedBox();
          },
        ),
      ),
    );
    return captured;
  }

  testWidgets('light theme exposes the extensions through context', (
    tester,
  ) async {
    final context = await pumpWith(tester, AppTheme.light);
    expect(context.colors.card, AppColors.light.card);
    expect(Theme.of(context).brightness, Brightness.light);
    expect(
      Theme.of(context).scaffoldBackgroundColor,
      AppColors.light.background,
    );
  });

  testWidgets('dark theme exposes the dark palette and the font family', (
    tester,
  ) async {
    final context = await pumpWith(tester, AppTheme.dark);
    expect(context.colors.card, AppColors.dark.card);
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(
      Theme.of(context).scaffoldBackgroundColor,
      AppColors.dark.background,
    );
    expect(context.text.of(AppFontSize.s14).fontFamily, AppTypography.family);
  });
}
