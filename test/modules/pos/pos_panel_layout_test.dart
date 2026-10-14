// Width math, thresholds and fallback of the three-panel POS layout (DEC-141).
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/theme/tokens/app_density_sizes.dart';
import 'package:pos_application/modules/pos/models/pos_panel_layout.dart';

PanelGeometry _geo(double work, {double billing = 307}) => PanelGeometry(
  workWidth: work,
  billingWidth: billing,
  gap: 16,
  edgeWidth: 36,
  edgeGap: 8,
  cartMinWide: AppDensitySizes.cartMinWide,
  cartMinNarrow: AppDensitySizes.cartMinNarrow,
  productsMinNarrow: AppDensitySizes.productsMinNarrow,
);

PanelLayout _l(int products, bool billing) =>
    PanelLayout(ProductsStep.fromPercent(products), billing: billing);

double _total(PanelGeometry g, PanelLayout l) {
  final w = g.widthsFor(l);
  return 36 + 8 + w.products + w.productsGap + w.cart + w.cartGap + w.billing;
}

void main() {
  test('cart share is the remainder of Products and Billing', () {
    expect(_l(0, true).cartPercent, 75);
    expect(_l(25, true).cartPercent, 50);
    expect(_l(75, true).cartPercent, 0);
    expect(_l(0, false).cartPercent, 100);
    expect(_l(25, false).cartPercent, 75);
    expect(_l(75, false).cartPercent, 25);
  });

  test('the widths of every state add up to the work width', () {
    final g = _geo(1184);
    for (final p in <int>[0, 25, 75]) {
      for (final b in <bool>[true, false]) {
        expect(_total(g, _l(p, b)), closeTo(1184, 0.001), reason: 'P$p/$b');
      }
    }
  });

  test('products : cart follows the percentages', () {
    final g = _geo(1184);
    var w = g.widthsFor(_l(25, true));
    expect(w.cart / w.products, closeTo(2, 0.001));
    expect(w.billing, 307);
    w = g.widthsFor(_l(25, false));
    expect(w.cart / w.products, closeTo(3, 0.001));
    w = g.widthsFor(_l(75, false));
    expect(w.products / w.cart, closeTo(3, 0.001));
    w = g.widthsFor(_l(75, true));
    expect(w.cart, 0);
    expect(w.productsGap, 16, reason: 'products, then billing');
    expect(w.cartGap, 0);
    w = g.widthsFor(_l(0, true));
    expect(w.products, 0);
    expect(w.productsGap, 0);
    expect(w.cartGap, 16);
  });

  test('a closed Billing and a closed Products take no gap', () {
    final w = _geo(1184).widthsFor(_l(0, false));
    expect(w.billing, 0);
    expect(w.cartGap, 0);
    expect(w.cart, 1184 - 36 - 8);
  });

  test('thresholds: which states fit where', () {
    // 1280 wide window: work area 1184 (sidebar 64).
    final wide = _geo(1184);
    for (final p in <int>[0, 25, 75]) {
      for (final b in <bool>[true, false]) {
        expect(wide.fits(_l(p, b)), isTrue, reason: 'P$p/$b at 1184');
      }
    }
    // 950 wide: work area 838, Billing 300.
    final narrow = _geo(838, billing: 300);
    expect(narrow.fits(_l(0, true)), isTrue, reason: 'default is exempt');
    expect(narrow.fits(_l(25, true)), isFalse);
    expect(narrow.fits(_l(25, false)), isTrue);
    expect(narrow.fits(_l(75, false)), isFalse, reason: 'cart 25% < 280');
    expect(narrow.fits(_l(75, true)), isTrue, reason: 'cart 0 always fits');
  });

  test('fallback closes Billing first, then shrinks Products', () {
    final narrow = _geo(838, billing: 300);
    expect(narrow.fit(_l(25, true)), _l(25, false));
    expect(narrow.fit(_l(75, false)), _l(25, false));
    expect(narrow.fit(_l(75, true)), _l(75, true));
    expect(narrow.fit(_l(0, true)), _l(0, true));
    // A window too small even for 25% + closed billing ends at Products off.
    final tiny = _geo(500, billing: 300);
    expect(tiny.fit(_l(25, false)), _l(0, false));
    expect(tiny.fit(_l(25, true)), _l(0, false));
  });

  test('P25/B25 needs a work width of about 1180', () {
    // Cart (2/3 of the shared width) >= 480 once the shared width is 720.
    // Work = 720 + 36 + 8 + 16 gap + 307 billing + 16 gap = 1103.
    expect(_geo(1102).fits(_l(25, true)), isFalse);
    expect(_geo(1104).fits(_l(25, true)), isTrue);
  });

  test('percent round trip', () {
    for (final s in ProductsStep.values) {
      expect(ProductsStep.fromPercent(s.percent), s);
    }
    expect(ProductsStep.fromPercent(33), ProductsStep.off);
  });
}
