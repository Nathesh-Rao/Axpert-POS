// Token values trace to docs/css_metrics.md (cascade-resolved at the reference
// viewport); test/core/theme/css_metrics_test.dart asserts they match.

/// Border radii in logical px (CSS px). `full` stands for `border-radius: 50%`.
abstract final class AppRadii {
  /// .qty-control 4px, .global-search kbd
  static const double r4 = 4.0;

  /// .product-image, .qty-badge, .chart-track
  static const double r5 = 5.0;

  /// .membership input (base), .popover button
  static const double r6 = 6.0;

  /// .customer-chip, .field (base), .categories button
  static const double r7 = 7.0;

  /// .action, .primary, .secondary, .segmented (most used)
  static const double r8 = 8.0;

  /// .global-search, .product-card, .search-results
  static const double r9 = 9.0;

  /// .popover, payment buttons (236), .invoice (236), .complete-payment
  static const double r10 = 10.0;

  /// .stat-tiles; `--radius` base (dead: 236 sets 14)
  static const double r11 = 11.0;

  /// .cart-line (236), quick-action tiles (236)
  static const double r12 = 12.0;

  /// .panel, .summary-card, `--radius` (236), .modal-symbol
  static const double r14 = 14.0;

  /// .modal, .sign-card, .drawer (left corners)
  static const double r16 = 16.0;

  /// .sale-toggle pills, .qty-control (236)
  static const double r22 = 22.0;

  /// border-radius:50% (circles: avatar, dots, badges, trash, qty buttons)
  static const double full = 9999.0;

  /// All values by name, for the css_metrics tests.
  static const Map<String, num> all = <String, num>{
    'r4': r4,
    'r5': r5,
    'r6': r6,
    'r7': r7,
    'r8': r8,
    'r9': r9,
    'r10': r10,
    'r11': r11,
    'r12': r12,
    'r14': r14,
    'r16': r16,
    'r22': r22,
    'full': full,
  };
}
