// The ONLY file that imports google_fonts (DEC-044). Bundling the fonts later
// is a change to this file alone.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font sizes (logical px) used by the prototype after the cascade
/// (css_metrics.md, "Typography"). Fluid `clamp()` sizes are resolved at the
/// reference viewport; AppMetrics (step 1.4b) handles other window sizes.
enum AppFontSize {
  s9(9),
  s10(10),
  s11(11),
  s12(12),
  s13(13),
  s14(14),
  s15(15),
  s16(16),
  s17(17),
  s18(18),
  s20(20),
  s21(21),
  s22(22),
  s23(23),
  s25(25),
  s26(26),
  s27(27),
  s28(28),
  s29(29),
  s30(30),
  s32(32),
  s36(36),
  s38(38);

  const AppFontSize(this.px);
  final double px;
}

/// The four Roboto Condensed weights the prototype loads (400/500/600/700).
enum AppFontWeight {
  regular(FontWeight.w400),
  medium(FontWeight.w500),
  semiBold(FontWeight.w600),
  bold(FontWeight.w700);

  const AppFontWeight(this.value);
  final FontWeight value;
}

/// Letter spacing (px) and line heights used by the prototype.
abstract final class AppTracking {
  static const double brand = -0.6;
  static const double catalogCaption = 1.1;
  static const double managementEyebrow = 1.2;
  static const double invoiceTotal = -0.5;
  static const double receiptBrand = 3;
}

abstract final class AppLineHeight {
  static const double summaryTitle = 1.1;
  static const double lineName = 1.3;
  static const double lineSmall = 1.2;
  static const double modalBody = 1.5;
}

abstract final class AppTypography {
  /// Family name used for the bundled test fonts.
  static const String family = 'RobotoCondensed';

  static bool _useBundledFonts = false;
  static final Map<(AppFontSize, AppFontWeight), TextStyle> _cache =
      <(AppFontSize, AppFontWeight), TextStyle>{};

  /// When true, text uses the plain [family] asset instead of the
  /// google_fonts package, so tests never touch the network. Tests load the
  /// TTFs from test/fonts with FontLoader (test/golden/harness.dart).
  static bool get useBundledFonts => _useBundledFonts;
  static set useBundledFonts(bool value) {
    _useBundledFonts = value;
    _cache.clear();
  }

  /// A Roboto Condensed [TextStyle] without color (color comes from the theme).
  static TextStyle style(
    AppFontSize size, {
    AppFontWeight weight = AppFontWeight.regular,
    double? letterSpacing,
    double? height,
  }) {
    if (letterSpacing != null || height != null) {
      return _build(size, weight, letterSpacing, height);
    }
    return _cache.putIfAbsent((
      size,
      weight,
    ), () => _build(size, weight, null, null));
  }

  static TextStyle _build(
    AppFontSize size,
    AppFontWeight weight,
    double? letterSpacing,
    double? height,
  ) {
    if (_useBundledFonts) {
      return TextStyle(
        fontFamily: family,
        fontSize: size.px,
        fontWeight: weight.value,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
    return GoogleFonts.robotoCondensed(
      fontSize: size.px,
      fontWeight: weight.value,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Material text theme in Roboto Condensed with [color] as text color.
  static TextTheme textTheme(TextTheme base, Color color) {
    final themed = _useBundledFonts
        ? base.apply(fontFamily: family)
        : GoogleFonts.robotoCondensedTextTheme(base);
    return themed.apply(bodyColor: color, displayColor: color);
  }
}

/// `context.text`: Roboto Condensed styles by prototype size and weight.
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles();

  TextStyle of(
    AppFontSize size, {
    AppFontWeight weight = AppFontWeight.regular,
    double? letterSpacing,
    double? height,
  }) => AppTypography.style(
    size,
    weight: weight,
    letterSpacing: letterSpacing,
    height: height,
  );

  @override
  AppTextStyles copyWith() => this;

  @override
  AppTextStyles lerp(ThemeExtension<AppTextStyles>? other, double t) => this;
}
