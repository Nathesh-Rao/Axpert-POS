// Token values trace to docs/css_metrics.md (cascade-resolved at the reference
// viewport); test/core/theme/css_metrics_test.dart asserts they match.

/// Spacing values in logical px. The prototype has no spacing scale: these are the px values it uses.
abstract final class AppSpacing {
  /// px values used by padding/margin/gap in index.css
  static const double s2 = 2.0;

  /// px values used by padding/margin/gap in index.css
  static const double s3 = 3.0;

  /// px values used by padding/margin/gap in index.css
  static const double s4 = 4.0;

  /// px values used by padding/margin/gap in index.css
  static const double s5 = 5.0;

  /// px values used by padding/margin/gap in index.css
  static const double s6 = 6.0;

  /// px values used by padding/margin/gap in index.css
  static const double s7 = 7.0;

  /// px values used by padding/margin/gap in index.css
  static const double s8 = 8.0;

  /// px values used by padding/margin/gap in index.css
  static const double s9 = 9.0;

  /// px values used by padding/margin/gap in index.css
  static const double s10 = 10.0;

  /// px values used by padding/margin/gap in index.css
  static const double s11 = 11.0;

  /// px values used by padding/margin/gap in index.css
  static const double s12 = 12.0;

  /// px values used by padding/margin/gap in index.css
  static const double s13 = 13.0;

  /// px values used by padding/margin/gap in index.css
  static const double s14 = 14.0;

  /// px values used by padding/margin/gap in index.css
  static const double s15 = 15.0;

  /// px values used by padding/margin/gap in index.css
  static const double s16 = 16.0;

  /// px values used by padding/margin/gap in index.css
  static const double s17 = 17.0;

  /// px values used by padding/margin/gap in index.css
  static const double s18 = 18.0;

  /// px values used by padding/margin/gap in index.css
  static const double s19 = 19.0;

  /// px values used by padding/margin/gap in index.css
  static const double s20 = 20.0;

  /// px values used by padding/margin/gap in index.css
  static const double s21 = 21.0;

  /// px values used by padding/margin/gap in index.css
  static const double s22 = 22.0;

  /// px values used by padding/margin/gap in index.css
  static const double s23 = 23.0;

  /// px values used by padding/margin/gap in index.css
  static const double s24 = 24.0;

  /// px values used by padding/margin/gap in index.css
  static const double s25 = 25.0;

  /// px values used by padding/margin/gap in index.css
  static const double s27 = 27.0;

  /// px values used by padding/margin/gap in index.css
  static const double s28 = 28.0;

  /// px values used by padding/margin/gap in index.css
  static const double s30 = 30.0;

  /// px values used by padding/margin/gap in index.css
  static const double s32 = 32.0;

  /// --panel-pad (236 overrides the clamp)
  static const double panelPad = 16.0;

  /// --layout-gap (236 overrides the clamp)
  static const double layoutGap = 16.0;

  /// All values by name, for the css_metrics tests and the swatch page.
  static const Map<String, num> all = <String, num>{
    's2': s2,
    's3': s3,
    's4': s4,
    's5': s5,
    's6': s6,
    's7': s7,
    's8': s8,
    's9': s9,
    's10': s10,
    's11': s11,
    's12': s12,
    's13': s13,
    's14': s14,
    's15': s15,
    's16': s16,
    's17': s17,
    's18': s18,
    's19': s19,
    's20': s20,
    's21': s21,
    's22': s22,
    's23': s23,
    's24': s24,
    's25': s25,
    's27': s27,
    's28': s28,
    's30': s30,
    's32': s32,
    'panelPad': panelPad,
    'layoutGap': layoutGap,
  };
}
