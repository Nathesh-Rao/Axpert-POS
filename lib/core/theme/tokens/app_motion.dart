// Token values trace to docs/css_metrics.md (cascade-resolved at the reference
// viewport); test/core/theme/css_metrics_test.dart asserts they match.

/// Motion values: durations in milliseconds, offsets in px (see source column in css_metrics.md).
abstract final class AppMotion {
  /// button transition .18s
  static const int buttonMs = 180;

  /// .product-card transition .2s; .toast/.modal slide-in .2s
  static const int cardMs = 200;

  /// .center-column slide-in .25s ease; .main grid transition .25s
  static const int slideInMs = 250;

  /// .qty-control button transition .15s
  static const int qtyButtonMs = 150;

  /// .cart-line.highlight-line animation 1.6s
  static const int highlightMs = 1600;

  /// .spinner 1s linear infinite
  static const int spinMs = 1000;

  /// @keyframes slide-in translateX(18px) (px, not ms)
  static const int slideInOffset = 18;

  /// button:active translateY(1px) (px)
  static const int pressTranslate = 1;

  /// All values by name, for the css_metrics tests and the swatch page.
  static const Map<String, num> all = <String, num>{
    'buttonMs': buttonMs,
    'cardMs': cardMs,
    'slideInMs': slideInMs,
    'qtyButtonMs': qtyButtonMs,
    'highlightMs': highlightMs,
    'spinMs': spinMs,
    'slideInOffset': slideInOffset,
    'pressTranslate': pressTranslate,
  };
}
