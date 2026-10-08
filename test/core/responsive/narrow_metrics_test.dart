import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';
import 'package:pos_application/core/responsive/clamp_rule.dart';
import 'package:pos_application/core/responsive/summary_metrics.dart';

AppMetrics _at(double w, [double h = 1000]) => AppMetrics(Size(w, h));

void main() {
  final ref = AppMetrics(AppMetrics.referenceSize);

  group('cart line layout and table header by width', () {
    test('wide (reference): single row, header equals the line columns', () {
      expect(ref.cartLineLayout, CartLineLayout.single);
      expect(ref.lineStacked, isFalse);
      expect(ref.cartHeaderColumns, same(CartHeaderColumns.wide));
      expect(ref.qtyControlWidth, 144);
      expect(ref.qtyControlHeight, 40);
      expect(ref.qtyButtonSize, 40);
      expect(ref.lineEditHeight, 36);
      expect(ref.lineEditFont, 14);
      expect(ref.lineNumberFont, 13);
      expect(ref.showLineImage, isTrue);
      expect(ref.showLineBarcode, isTrue);
      expect(ref.cartActionsStacked, isFalse);
      expect(ref.cartTimeOnOwnRow, isFalse);
    });

    test('1701 is wide, 1700 is stacked', () {
      expect(_at(1701).lineStacked, isFalse);
      expect(_at(1700).lineStacked, isTrue);
      expect(_at(1701).cartHeaderColumns, same(CartHeaderColumns.wide));
      expect(_at(1700).cartHeaderColumns, same(CartHeaderColumns.stacked));
    });

    test('the wide header columns are the line columns', () {
      final c = CartHeaderColumns.wide;
      expect(c.gap, 8);
      expect(c.columns.map((e) => e.width), [20, null, 144, 76, 76, null, 40]);
      expect(c.columns.map((e) => e.flex), [0, 16, 0, 0, 0, 8, 0]);
    });

    test('the stacked header keeps its own six columns (prototype)', () {
      final c = CartHeaderColumns.stacked;
      expect(c.gap, 4);
      expect(c.columns.map((e) => e.width), [
        18,
        null,
        null,
        null,
        null,
        null,
        0,
      ]);
      expect(c.columns.map((e) => e.flex), [0, 14, 13, 8, 8, 10, 0]);
    });

    for (final w in <double>[1700, 1440, 1280, 1100, 1000]) {
      test('stacked line values at $w', () {
        final m = _at(w);
        expect(m.cartLineLayout, CartLineLayout.stacked);
        expect(m.qtyControlWidth, 152);
        expect(m.qtyControlHeight, 44);
        expect(m.qtyButtonSize, 44);
        expect(m.lineEditHeight, 44);
        expect(m.lineNumberFont, 12);
        expect(m.cartActionsStacked, isTrue);
        expect(m.cartActionsStackedGap, 3);
      });
    }

    test('image and barcode hide only at width <= 1100', () {
      for (final w in <double>[1868, 1700, 1440, 1280, 1101]) {
        expect(_at(w).showLineImage, isTrue, reason: '$w');
        expect(_at(w).showLineBarcode, isTrue, reason: '$w');
      }
      for (final w in <double>[1100, 1000]) {
        expect(_at(w).showLineImage, isFalse, reason: '$w');
        expect(_at(w).showLineBarcode, isFalse, reason: '$w');
      }
    });

    test('price and discount text is 13 at width <= 1100, else 14', () {
      expect(_at(1101).lineEditFont, 14);
      expect(_at(1100).lineEditFont, 13);
    });
  });

  group('cart heading', () {
    test('clock on its own row and gap 5 at width <= 1280', () {
      expect(_at(1281).cartTimeOnOwnRow, isFalse);
      expect(_at(1280).cartTimeOnOwnRow, isTrue);
      expect(_at(1280).cartHeadingGap, 5);
      expect(_at(1440).cartHeadingGap, closeTo(7.2, 0.01));
      expect(ref.cartHeadingGap, 9);
    });

    test('counter 16 and icon 19 at width <= 1100', () {
      expect(_at(1100).cartHeadingFont, 16);
      expect(_at(1100).cartHeadingIcon, 19);
      expect(_at(1101).cartHeadingFont, closeTo(17, 0.01));
      expect(_at(1440).cartHeadingFont, closeTo(18, 0.01));
      expect(_at(1440).cartHeadingIcon, closeTo(24.48, 0.01));
      expect(ref.cartHeadingFont, 22);
    });

    test('min height 30 at height <= 820', () {
      expect(_at(1900, 820).cartHeadingMinHeight, 30);
      expect(_at(1900, 821).cartHeadingMinHeight, closeTo(36.945, 0.01));
      expect(ref.cartHeadingMinHeight, 44);
    });
  });

  group('stat tiles', () {
    test('wide', () {
      expect(ref.statTilesPad, 12);
      expect(ref.statTilesGap, 12);
      expect(ref.statTilePadY, 16);
      expect(ref.statTilePadX, 8);
      expect(ref.statTileGap, 8);
      expect(ref.statTileIcon, 26);
      expect(ref.statTileValueFont, closeTo(27.09, 0.01));
      expect(ref.showStatTileIcon, isTrue);
      expect(ref.statTilesVertical, isFalse);
    });

    test('width <= 1700', () {
      final m = _at(1440);
      expect(m.statTilePadY, 14);
      expect(m.statTilePadX, 5);
      expect(m.statTileGap, 5);
      expect(m.statTileIcon, 21);
      expect(m.statTileValueFont, closeTo(21.6, 0.01));
      expect(_at(1700).statTileValueFont, 24);
      expect(m.showStatTileIcon, isTrue);
      expect(m.statTilesPad, 12);
    });

    test('width <= 1100: vertical tiles without icon', () {
      final m = _at(1100);
      expect(m.statTilesVertical, isTrue);
      expect(m.showStatTileIcon, isFalse);
      expect(m.statTilesPad, 8);
      expect(m.statTilesGap, 8);
      expect(m.statTilePadY, 12);
      expect(m.statTilePadX, 5);
      // The <= 1100 value font (16) is overridden by the <= 1700 clamp.
      expect(m.statTileValueFont, 18);
      expect(_at(1101).statTilesVertical, isFalse);
    });
  });

  group('catalog rules in the same media blocks', () {
    test('2 columns with the cart open at width <= 1280', () {
      expect(_at(1280).catalogFixedColumns(cartOpen: true, list: false), 2);
      expect(
        _at(1281).catalogFixedColumns(cartOpen: true, list: false),
        isNull,
      );
      expect(
        _at(1280).catalogFixedColumns(cartOpen: false, list: false),
        isNull,
      );
      expect(_at(1280).catalogFixedColumns(cartOpen: true, list: true), isNull);
    });

    test('price 11 and stepper gap 2 at width <= 1100', () {
      expect(_at(1100).productPriceFont, 11);
      expect(_at(1100).productStepperGap, 2);
      expect(_at(1101).productPriceFont, closeTo(12, 0.1));
      expect(_at(1101).productStepperGap, 3);
      expect(ref.productPriceFont, 15);
    });
  });

  group('summary density (metrics for S4.a)', () {
    test('thresholds are inclusive', () {
      expect(_at(1900, 961).summaryDensity, SummaryDensity.normal);
      expect(_at(1900, 960).summaryDensity, SummaryDensity.compact);
      expect(_at(1900, 821).summaryDensity, SummaryDensity.compact);
      expect(_at(1900, 820).summaryDensity, SummaryDensity.tight);
      expect(_at(1900, 720).memberCollapsed, isFalse);
      expect(_at(1900, 719).memberCollapsed, isTrue);
    });

    test('normal at the reference viewport', () {
      final s = ref.summary;
      expect(s.density, SummaryDensity.normal);
      expect(s.panelPad, closeTo(16.55, 0.01));
      expect(s.gap, 8);
      expect(s.titleHeight, 24);
      expect(s.rowHeight, closeTo(33.11, 0.01));
      expect(s.invoiceHeight, closeTo(57.94, 0.01));
      expect(s.invoiceTotalFont, closeTo(25.87, 0.01));
      expect(s.currencyRowHeight, 40);
      expect(s.membershipInputHeight, 38);
      expect(s.checkoutGap, 10);
      expect(s.paymentButtonHeight, 56);
      expect(s.completeHeight, 48);
      expect(s.tenderedHeight, 44);
      expect(s.quickAmountHeight, 36);
      expect(s.terminalHeight, 90);
      expect(s.declineHeight, 54);
      expect(s.quickActionSize, 52);
      expect(s.quickActionsGap, 10);
    });

    test('compact (height 900)', () {
      final s = _at(1900, 900).summary;
      expect(s.density, SummaryDensity.compact);
      expect(s.panelPad, 14);
      expect(s.gap, 4);
      expect(s.titleHeight, 22);
      expect(s.titleFont, 18);
      expect(s.cardPad, 8); // CSS 6, DEC-100
      expect(s.rowHeight, closeTo(27.9, 0.01));
      expect(s.invoiceHeight, closeTo(49.5, 0.01));
      expect(s.invoicePad, 6);
      expect(s.invoiceTotalFont, 25);
      expect(s.currencyRowHeight, 32);
      expect(s.rateLabelHeight, 12);
      expect(s.membershipGap, 6);
      expect(s.membershipInputHeight, 28);
      expect(s.membershipFont, 12);
      expect(s.checkoutPad, 8);
      expect(s.checkoutGap, 8);
      expect(s.paymentButtonHeight, 40); // CSS 46, DEC-100
      expect(s.inlineGap, 4);
      expect(s.inlineAmountHeight, 22);
      expect(s.tenderedHeight, 34);
      expect(s.quickAmountHeight, 28);
      expect(s.completeHeight, 34); // CSS 36, DEC-100
      expect(s.completeFont, 14);
      expect(s.terminalHeight, 68);
      expect(s.declineHeight, 46);
      expect(s.quickActionSize, 40); // CSS 44, DEC-100
    });

    test('tight (height 780)', () {
      final s = _at(1900, 780).summary;
      expect(s.density, SummaryDensity.tight);
      expect(s.gap, 3);
      expect(s.titleHeight, 20);
      expect(s.titleFont, 17);
      expect(s.cardPad, 8); // CSS 4, DEC-100
      expect(s.rowHeight, 21);
      expect(s.rowFont, 12);
      expect(s.rowValueFont, 13);
      expect(s.invoiceHeight, 42);
      expect(s.invoicePad, 5);
      expect(s.invoiceTotalFont, 24);
      expect(s.currencyRowHeight, 28);
      expect(s.membershipInputHeight, 22);
      expect(s.membershipLabelGap, 4); // CSS 2, DEC-100
      expect(s.applyDiscountHeight, 27);
      expect(s.applyDiscountMarginBottom, 4);
      expect(s.applyDiscountFont, 11);
      expect(s.checkoutPad, 8); // CSS 6, DEC-100
      expect(s.checkoutGap, 6);
      expect(s.paymentButtonHeight, 30); // CSS 46, DEC-100
      expect(s.inlineGap, 4); // CSS 3, DEC-100
      expect(s.inlineAmountHeight, 20);
      expect(s.tenderedHeight, 30); // CSS 32, DEC-100
      expect(s.quickAmountHeight, 24); // CSS 26, DEC-100
      expect(s.quickAmountFont, 12);
      expect(s.completeHeight, 28); // CSS 34, DEC-100
      expect(s.completeFont, 13);
      expect(s.terminalHeight, 64);
      expect(s.declineHeight, 40);
      expect(s.quickActionsGap, 4); // CSS 8, DEC-100
      expect(s.quickActionSize, 30); // CSS 44, DEC-100
      expect(s.membershipGap, 4); // CSS 6, DEC-100
    });

    test('inner padding tokens hold at every density and height (DEC-100)', () {
      for (final h in <double>[600, 719, 733, 820, 900, 960, 961, 1000, 1035]) {
        final s = _at(1900, h).summary;
        final why = 'height $h';
        expect(
          s.cardPad,
          greaterThanOrEqualTo(SummaryMetrics.minCardInset),
          reason: why,
        );
        expect(
          s.checkoutPad,
          greaterThanOrEqualTo(SummaryMetrics.minCardInset),
          reason: why,
        );
        expect(
          s.membershipLabelGap,
          greaterThanOrEqualTo(SummaryMetrics.minLabelGap),
          reason: why,
        );
        expect(
          s.inlineGap,
          greaterThanOrEqualTo(SummaryMetrics.minRowGap),
          reason: why,
        );
        expect(
          s.membershipGap,
          greaterThanOrEqualTo(SummaryMetrics.minRowGap),
          reason: why,
        );
        expect(
          s.quickActionsGap,
          greaterThanOrEqualTo(SummaryMetrics.minRowGap),
          reason: why,
        );
      }
      // Normal density stays the CSS one at the reference viewport.
      final ref = _at(1868, 1035).summary;
      expect(ref.cardPad, closeTo(8.28, 0.01));
      expect(ref.paymentButtonHeight, 56);
      expect(ref.completeHeight, 48);
      expect(ref.quickActionSize, 52);
    });

    test('collapsed member card values (height <= 719)', () {
      const c = ClampRule(1000, 700);
      expect(MemberCardMetrics.compactMinHeight, 34);
      expect(MemberCardMetrics.floatingTop(c), closeTo(154, 0.01));
      expect(MemberCardMetrics.floatingTop(const ClampRule(1000, 400)), 100);
      expect(MemberCardMetrics.floatingTop(const ClampRule(1000, 900)), 180);
      expect(MemberCardMetrics.floatingWidth(300), 264);
      expect(MemberCardMetrics.floatingInputHeight, 38);
    });
  });
}
