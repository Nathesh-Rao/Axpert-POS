import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';

void main() {
  final ref = AppMetrics(AppMetrics.referenceSize);

  test('every css_metrics section 10 row at the reference viewport', () {
    final expected = <String, (double, double)>{
      'rootFontSize': (ref.rootFontSize, 14.00),
      'topbarPadX': (ref.topbarPadX, 18.68),
      'topbarGap': (ref.topbarGap, 14.95),
      'brandGap': (ref.brandGap, 23.36),
      'brandFont': (ref.brandFont, 26.00),
      'brandMarkWidth': (ref.brandMarkWidth, 56.05),
      'brandMarkFont': (ref.brandMarkFont, 42.00),
      'storeWidth': (ref.storeWidth, 250.00),
      'storeFont': (ref.storeFont, 14.00),
      'searchHeight': (ref.searchHeight, 44.00),
      'searchMarginX': (ref.searchMarginX, 14.95),
      'searchFont': (ref.searchFont, 14.00),
      'avatarSize': (ref.avatarSize, 38.00),
      'sidebarGap': (ref.sidebarGap, 23.80),
      'sidebarButtonHeight': (ref.sidebarButtonHeight, 76.00),
      'sidebarIconSize': (ref.sidebarIconSize, 26.00),
      'emptyCustomerMarginBottom': (ref.emptyCustomerMarginBottom, 11.38),
      'emptyCustomerPaddingBottom': (ref.emptyCustomerPaddingBottom, 10.35),
      'customerSelectWidth': (ref.customerSelectWidth, 175.00),
      'customerSelectFont': (ref.customerSelectFont, 13.00),
      'saleTogglePadY': (ref.saleTogglePadY, 8.28),
      'saleTogglePadX': (ref.saleTogglePadX, 10.00),
      'categoryPadY': (ref.categoryPadY, 11.38),
      'categoryPadX': (ref.categoryPadX, 13.00),
      'subcategoriesMarginTop': (ref.subcategoriesMarginTop, 11.38),
      'subcategoryPadY': (ref.subcategoryPadY, 9.31),
      'subcategoryPadX': (ref.subcategoryPadX, 13.00),
      'catalogToolsMarginY': (ref.catalogToolsMarginY, 14.49),
      'fieldHeight': (ref.fieldHeight, 42.00),
      'fieldGap': (ref.fieldGap, 11.00),
      'fieldPadX': (ref.fieldPadX, 13.00),
      'viewToggleWidth': (ref.viewToggleWidth, 36.00),
      'viewToggleHeight': (ref.viewToggleHeight, 35.00),
      'productGridMinColumn': (ref.productGridMinColumn, 170.00),
      'productGridGap': (ref.productGridGap, 11.00),
      'productCardPad': (ref.productCardPad, 11.00),
      'productImageHeight': (ref.productImageHeight, 84.00),
      'productPriceFont': (ref.productPriceFont, 15.00),
      'productStepperButton': (ref.productStepperButton, 30.00),
      'productStepperFirst': (ref.productStepperFirst, 25.00),
      'cartHeadingMinHeight': (ref.cartHeadingMinHeight, 44.00),
      'cartHeadingGap': (ref.cartHeadingGap, 9.00),
      'cartHeadingFont': (ref.cartHeadingFont, 22.00),
      'cartHeadingIcon': (ref.cartHeadingIcon, 26.00),
      'customerLabelMarginTop': (ref.customerLabelMarginTop, 10.35),
      'cartTableMarginTop': (ref.cartTableMarginTop, 12.42),
      'cartLineMinHeight': (ref.cartLineMinHeight, 96.00),
      'statTileValueFont': (ref.statTileValueFont, 27.09),
      'billSummaryPad': (ref.billSummaryPad, 16.55),
      'billSummaryGap': (ref.billSummaryGap, 8.00),
      'billSummaryTitleFont': (ref.billSummaryTitleFont, 22.00),
      'summaryCardPad': (ref.summaryCardPad, 8.28),
      'summaryRowHeight': (ref.summaryRowHeight, 33.11),
      'summaryRowValueFont': (ref.summaryRowValueFont, 16.00),
      'invoiceHeight': (ref.invoiceHeight, 57.94),
      'invoiceLabelFont': (ref.invoiceLabelFont, 16.82),
      'invoiceTotalFont': (ref.invoiceTotalFont, 25.87),
      'checkoutSectionPad': (ref.checkoutSectionPad, 13.45),
      'checkoutGap': (ref.checkoutGap, 10.00),
      'paymentButtonHeight': (ref.paymentButtonHeight, 56.00),
      'paymentButtonFont': (ref.paymentButtonFont, 20.00),
      'tenderedFont': (ref.summary.tenderedFont, 22.00),
      'quickActionTile': (ref.quickActionTile, 52.00),
      'managementPad': (ref.managementPad, 28.00),
      'modalOverlayPad': (ref.modalOverlayPad, 25.00),
      'modalPad': (ref.modalPad, 32.00),
    };
    expect(expected.length, 66);
    expected.forEach((name, pair) {
      expect(pair.$1, closeTo(pair.$2, 0.01), reason: name);
    });
  });

  test('reference viewport: no media query applies', () {
    expect(ref.atMost1700, isFalse);
    expect(ref.atMost1280, isFalse);
    expect(ref.atMost1100, isFalse);
    expect(ref.heightAtMost960, isFalse);
    expect(ref.summaryDensity, SummaryDensity.normal);
    expect(ref.cartLineLayout, CartLineLayout.single);
    expect(ref.topbarHeight, 64);
    expect(ref.sidebarWidth, 80);
    expect(ref.summaryWidth(isPos: true), 380);
    expect(ref.summaryWidth(isPos: false), 310);
    expect(ref.showShortcutHint, isTrue);
    expect(ref.showProfileText, isTrue);
  });

  test(
    'breakpoints are inclusive and change the shell values (regression)',
    () {
      final w1700 = AppMetrics(const Size(1700, 1000));
      expect(w1700.atMost1700, isTrue);
      expect(w1700.cartLineLayout, CartLineLayout.stacked);
      expect(AppMetrics(const Size(1701, 1000)).atMost1700, isFalse);

      final w1280 = AppMetrics(const Size(1280, 1000));
      expect(w1280.topbarHeight, 56);
      expect(w1280.sidebarWidth, 64);
      expect(w1280.showShortcutHint, isFalse);
      expect(w1280.showProfileText, isFalse);
      expect(w1280.topbarGap, 8);
      expect(w1280.searchMarginX, 3);
      expect(w1280.profilePadLeft, 8);
      expect(ref.profilePadLeft, 10);
      expect(ref.profileGap, 8);

      final w1100 = AppMetrics(const Size(1100, 1000));
      expect(w1100.brandFont, 19);
      expect(w1100.brandMarkWidth, 28);
      expect(w1100.storeWidth, 160);
      expect(w1100.panelPad, 12);
      expect(w1100.brandGap, 6);
    },
  );

  test('height breakpoints select the summary density (regression)', () {
    expect(
      AppMetrics(const Size(1900, 960)).summaryDensity,
      SummaryDensity.compact,
    );
    expect(
      AppMetrics(const Size(1900, 820)).summaryDensity,
      SummaryDensity.tight,
    );
    expect(
      AppMetrics(const Size(1900, 961)).summaryDensity,
      SummaryDensity.normal,
    );
    expect(AppMetrics(const Size(1900, 719)).heightAtMost719, isTrue);
  });

  test('clamp rules saturate at both ends', () {
    final small = AppMetrics(const Size(800, 500));
    expect(small.sidebarButtonHeight, 48);
    expect(small.searchHeight, 36);
    expect(small.summaryWidth(isPos: true), 300);
    final big = AppMetrics(const Size(3000, 2000));
    expect(big.sidebarButtonHeight, 76);
    expect(big.summaryWidth(isPos: true), 380);
  });
}
