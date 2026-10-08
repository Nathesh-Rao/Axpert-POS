import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';

void main() {
  setUp(() => AppTypography.useBundledFonts = true);
  tearDownAll(() => AppTypography.useBundledFonts = false);

  test('four weights map to 400/500/600/700', () {
    expect(AppFontWeight.values.map((w) => w.value), const [
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
    ]);
  });

  test('styles carry the requested size, weight and family', () {
    final s = AppTypography.style(
      AppFontSize.s26,
      weight: AppFontWeight.bold,
      letterSpacing: AppTracking.brand,
    );
    expect(s.fontSize, 26);
    expect(s.fontWeight, FontWeight.w700);
    expect(s.letterSpacing, -0.6);
    expect(s.fontFamily, AppTypography.family);
    expect(s.color, isNull, reason: 'color comes from the theme');
  });

  test('plain styles are cached, custom ones are not', () {
    expect(
      identical(
        AppTypography.style(AppFontSize.s12),
        AppTypography.style(AppFontSize.s12),
      ),
      isTrue,
    );
    expect(
      identical(
        AppTypography.style(AppFontSize.s12, height: 1.2),
        AppTypography.style(AppFontSize.s12, height: 1.2),
      ),
      isFalse,
    );
  });

  test('every prototype font size is declared', () {
    expect(
      AppFontSize.values.map((s) => s.px.toInt()),
      containsAll(<int>[
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        17,
        18,
        20,
        21,
        22,
        23,
        25,
        26,
        27,
        28,
        29,
        30,
        32,
        36,
        38,
      ]),
    );
  });
}
