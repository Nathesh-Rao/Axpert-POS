import 'dart:math' as math;

/// Width of the Products panel as a share of the work area (DEC-141).
enum ProductsStep {
  off(0),
  narrow(25),
  wide(75);

  const ProductsStep(this.percent);

  /// 0, 25 or 75.
  final int percent;

  /// The step stored as [percent]; anything unknown is [off].
  static ProductsStep fromPercent(int percent) => values.firstWhere(
    (s) => s.percent == percent,
    orElse: () => ProductsStep.off,
  );
}

/// A POS work-area layout: the Products step and whether Billing is open. The
/// cart takes whatever is left (100 - products - billing, Billing counting as
/// 25).
class PanelLayout {
  const PanelLayout(this.products, {required this.billing});

  final ProductsStep products;
  final bool billing;

  /// Share left for the cart: 0, 25, 50, 75 or 100.
  int get cartPercent => 100 - products.percent - (billing ? 25 : 0);

  /// The catalog-dominant layouts (Products 75%): the cart is hidden or a
  /// quarter wide.
  bool get catalogDominant => products == ProductsStep.wide;

  PanelLayout withProducts(ProductsStep step) =>
      PanelLayout(step, billing: billing);

  PanelLayout withBilling({required bool open}) =>
      PanelLayout(products, billing: open);

  @override
  bool operator ==(Object other) =>
      other is PanelLayout &&
      other.products == products &&
      other.billing == billing;

  @override
  int get hashCode => Object.hash(products, billing);

  @override
  String toString() => 'P${products.percent}/B${billing ? 25 : 0}';
}

/// Widths of the panels and of the two gaps between them, in logical pixels.
/// A closed panel is 0 wide and its gap is 0.
class PanelWidths {
  const PanelWidths({
    required this.products,
    required this.cart,
    required this.billing,
    required this.productsGap,
    required this.cartGap,
  });

  static const PanelWidths zero = PanelWidths(
    products: 0,
    cart: 0,
    billing: 0,
    productsGap: 0,
    cartGap: 0,
  );

  final double products;
  final double cart;
  final double billing;

  /// Gap after the Products panel (only when something visible follows it).
  final double productsGap;

  /// Gap after the cart (only when Billing follows it).
  final double cartGap;

  static PanelWidths lerp(PanelWidths a, PanelWidths b, double t) =>
      PanelWidths(
        products: a.products + (b.products - a.products) * t,
        cart: a.cart + (b.cart - a.cart) * t,
        billing: a.billing + (b.billing - a.billing) * t,
        productsGap: a.productsGap + (b.productsGap - a.productsGap) * t,
        cartGap: a.cartGap + (b.cartGap - a.cartGap) * t,
      );

  @override
  bool operator ==(Object other) =>
      other is PanelWidths &&
      other.products == products &&
      other.cart == cart &&
      other.billing == billing &&
      other.productsGap == productsGap &&
      other.cartGap == cartGap;

  @override
  int get hashCode =>
      Object.hash(products, cart, billing, productsGap, cartGap);

  @override
  String toString() =>
      'products $products, cart $cart, billing $billing '
      '(gaps $productsGap, $cartGap)';
}

/// The numbers the layout needs from the window and the tokens. Pure data, no
/// Flutter: [widthsFor] and [fit] are plain functions so they are unit tested.
class PanelGeometry {
  const PanelGeometry({
    required this.workWidth,
    required this.billingWidth,
    required this.gap,
    required this.edgeWidth,
    required this.edgeGap,
    required this.cartMinWide,
    required this.cartMinNarrow,
    required this.productsMinNarrow,
  });

  /// Everything right of the navigation rail: the edge control, the panels
  /// and Billing.
  final double workWidth;

  /// Width of Billing when open (`summaryWidth`, unchanged by this layout).
  final double billingWidth;

  /// Gap between panels (`layoutGap`).
  final double gap;

  /// The edge control and its gap to the first panel.
  final double edgeWidth;
  final double edgeGap;

  final double cartMinWide;
  final double cartMinNarrow;
  final double productsMinNarrow;

  /// Width shared by Products and the cart (edge control, Billing and the
  /// gaps taken off).
  double _shared(PanelLayout layout) {
    final billing = layout.billing ? billingWidth + gap : 0;
    final both = layout.products != ProductsStep.off && layout.cartPercent > 0
        ? gap
        : 0;
    return math.max(0, workWidth - billing - edgeWidth - edgeGap - both);
  }

  /// The widths of [layout] in this geometry (the gaps are part of the
  /// result, so the five values plus the edge control add up to [workWidth]).
  PanelWidths widthsFor(PanelLayout layout) {
    final shared = _shared(layout);
    final p = layout.products.percent;
    final c = layout.cartPercent;
    final double products;
    final double cart;
    if (p == 0) {
      products = 0;
      cart = shared;
    } else if (c == 0) {
      products = shared;
      cart = 0;
    } else {
      products = shared * p / (p + c);
      cart = shared * c / (p + c);
    }
    final billing = layout.billing ? billingWidth : 0.0;
    return PanelWidths(
      products: products,
      cart: cart,
      billing: billing,
      productsGap: products > 0 && (cart > 0 || billing > 0) ? gap : 0,
      cartGap: cart > 0 && billing > 0 ? gap : 0,
    );
  }

  /// Whether [layout] is readable in this window (rule 6).
  /// - cart at 50% or more: at least [cartMinWide], except the default
  ///   Products closed + Billing open, which keeps today's behavior;
  /// - cart at 25%: at least [cartMinNarrow];
  /// - narrow Products: at least [productsMinNarrow];
  /// - a cart of 0% always fits.
  bool fits(PanelLayout layout) {
    final w = widthsFor(layout);
    final c = layout.cartPercent;
    if (c >= 50) {
      final legacyDefault =
          layout.products == ProductsStep.off && layout.billing;
      if (!legacyDefault && w.cart < cartMinWide) return false;
    } else if (c > 0 && w.cart < cartMinNarrow) {
      return false;
    }
    if (layout.products == ProductsStep.narrow &&
        w.products < productsMinNarrow) {
      return false;
    }
    return true;
  }

  /// The nearest layout that fits: close Billing first, then shrink Products
  /// (75 -> 25 -> 0). The preference itself is never changed by this.
  PanelLayout fit(PanelLayout wanted) {
    var layout = wanted;
    while (!fits(layout)) {
      if (layout.billing) {
        layout = layout.withBilling(open: false);
      } else if (layout.products == ProductsStep.wide) {
        layout = layout.withProducts(ProductsStep.narrow);
      } else if (layout.products == ProductsStep.narrow) {
        layout = layout.withProducts(ProductsStep.off);
      } else {
        break;
      }
    }
    return layout;
  }
}
