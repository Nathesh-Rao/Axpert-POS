// Token values trace to docs/css_metrics.md (cascade-resolved at the reference
// viewport); test/core/theme/css_metrics_test.dart asserts they match.

import 'package:flutter/painting.dart';

/// One CSS box-shadow layer. Flutter's [BoxShadow] cannot draw `inset`
/// shadows, so inset layers are kept as data and drawn by the widget that
/// needs them (see decisions.md DEC-064).
class ShadowSpec {
  const ShadowSpec(
    this.dx,
    this.dy,
    this.blur,
    this.spread,
    this.color, {
    this.inset = false,
  });

  final double dx;
  final double dy;

  /// CSS blur radius (Flutter's blurRadius uses the same unit).
  final double blur;
  final double spread;
  final Color color;
  final bool inset;

  BoxShadow toBoxShadow() => BoxShadow(
    color: color,
    offset: Offset(dx, dy),
    blurRadius: blur,
    spreadRadius: spread,
  );
}

abstract final class AppShadows {
  /// .panel
  static const List<ShadowSpec> panel = <ShadowSpec>[
    ShadowSpec(0, 2, 16, 0, Color(0x0ABDCDE0)),
  ];

  /// .modal
  static const List<ShadowSpec> modal = <ShadowSpec>[
    ShadowSpec(0, 25, 80, 0, Color(0x440D2038)),
  ];

  /// .popover
  static const List<ShadowSpec> popover = <ShadowSpec>[
    ShadowSpec(0, 12, 40, 0, Color(0x20102047)),
  ];

  /// .search-results
  static const List<ShadowSpec> searchResults = <ShadowSpec>[
    ShadowSpec(0, 10, 30, 0, Color(0x2012294B)),
  ];

  /// .toast
  static const List<ShadowSpec> toast = <ShadowSpec>[
    ShadowSpec(0, 6, 30, 0, Color(0x2517294A)),
  ];

  /// .member-card.member-open .membership (height<=719)
  static const List<ShadowSpec> memberPanel = <ShadowSpec>[
    ShadowSpec(0, 8, 32, 0, Color(0x30102047)),
  ];

  /// .product-card:hover
  static const List<ShadowSpec> productHover = <ShadowSpec>[
    ShadowSpec(0, 4, 15, 0, Color(0x10276ED8)),
  ];

  /// .summary-card
  static const List<ShadowSpec> summaryCard = <ShadowSpec>[
    ShadowSpec(0, 2, 9, 0, Color(0x10193B67)),
  ];

  /// .cart-line (236)
  static const List<ShadowSpec> cartLine = <ShadowSpec>[
    ShadowSpec(0, 2, 8, 0, Color(0x0821416B)),
  ];

  /// .cart-line.selected-line (236)
  static const List<ShadowSpec> cartLineSelected = <ShadowSpec>[
    ShadowSpec(0, 3, 12, 0, Color(0x0C2076DF)),
  ];

  /// .action-tooltip
  static const List<ShadowSpec> tooltip = <ShadowSpec>[
    ShadowSpec(0, 4, 18, 0, Color(0x30142746)),
  ];

  /// .sign-card
  static const List<ShadowSpec> signCard = <ShadowSpec>[
    ShadowSpec(0, 15, 50, 0, Color(0x10123456)),
  ];

  /// .segmented .selected (CSS #0001 = #000000 at 0x11 alpha)
  static const List<ShadowSpec> segmentedSelected = <ShadowSpec>[
    ShadowSpec(0, 1, 4, 0, Color(0x11000000)),
  ];

  /// .payment-buttons button[aria-pressed=true] (236); second layer is inset
  static const List<ShadowSpec> payPressed = <ShadowSpec>[
    ShadowSpec(0, 3, 8, 0, Color(0x20125EAE)),
    ShadowSpec(0, 1, 1, 0, Color(0x40FFFFFF), inset: true),
  ];

  /// .quick-actions .action:hover (inset ring)
  static const List<ShadowSpec> quickActionHoverRing = <ShadowSpec>[
    ShadowSpec(0, 0, 0, 1, Color(0x33729BD4), inset: true),
  ];

  /// .qty-control (236) (inset ring)
  static const List<ShadowSpec> qtyControlRing = <ShadowSpec>[
    ShadowSpec(0, 0, 0, 1, Color(0xFFDBE5F3), inset: true),
  ];

  /// Non-inset layers of a shadow as Flutter [BoxShadow]s.
  static List<BoxShadow> boxShadows(List<ShadowSpec> spec) => <BoxShadow>[
    for (final s in spec)
      if (!s.inset) s.toBoxShadow(),
  ];

  static const Map<String, List<ShadowSpec>> all = <String, List<ShadowSpec>>{
    'panel': panel,
    'modal': modal,
    'popover': popover,
    'searchResults': searchResults,
    'toast': toast,
    'memberPanel': memberPanel,
    'productHover': productHover,
    'summaryCard': summaryCard,
    'cartLine': cartLine,
    'cartLineSelected': cartLineSelected,
    'tooltip': tooltip,
    'signCard': signCard,
    'segmentedSelected': segmentedSelected,
    'payPressed': payPressed,
    'quickActionHoverRing': quickActionHoverRing,
    'qtyControlRing': qtyControlRing,
  };
}

extension ShadowSpecListX on List<ShadowSpec> {
  /// Drawable layers (inset layers are skipped, see DEC-064).
  List<BoxShadow> get boxShadows => <BoxShadow>[
    for (final s in this)
      if (!s.inset) s.toBoxShadow(),
  ];
}
