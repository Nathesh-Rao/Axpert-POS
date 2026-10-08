import 'dart:ui' show Size;

import '../theme/tokens/app_sizes.dart';
import 'breakpoints.dart';
import 'clamp_rule.dart';

enum SummaryDensity { normal, compact, tight }

enum CartLineLayout { single, stacked }

/// The prototype's `clamp()/vw/vh` rules and media queries as explicit values
/// for one window size (docs/css_metrics.md section 10 and 11). Pure Dart, no
/// widgets, so every number is unit-testable. Values the shell does not use
/// yet are consumed from S3 on; media-query overrides of those arrive with
/// their consumers.
class AppMetrics {
  AppMetrics(Size size)
    : width = size.width,
      height = size.height,
      _c = ClampRule(size.width, size.height);

  /// The measured reference viewport (DEC-062).
  static const Size referenceSize = Size(1868.44, 1034.67);

  final double width;
  final double height;
  final ClampRule _c;

  // --- media-query flags ---------------------------------------------------
  bool get atMost1700 => Breakpoints.widthAtMost1700(width);
  bool get atMost1280 => Breakpoints.widthAtMost1280(width);
  bool get atMost1100 => Breakpoints.widthAtMost1100(width);
  bool get heightAtMost960 => Breakpoints.heightAtMost960(height);
  bool get heightAtMost820 => Breakpoints.heightAtMost820(height);
  bool get heightAtMost719 => Breakpoints.heightAtMost719(height);

  SummaryDensity get summaryDensity => heightAtMost820
      ? SummaryDensity.tight
      : heightAtMost960
      ? SummaryDensity.compact
      : SummaryDensity.normal;

  CartLineLayout get cartLineLayout =>
      atMost1700 ? CartLineLayout.stacked : CartLineLayout.single;

  // --- layout constants ------------------------------------------------------
  double get topbarHeight => atMost1280 ? 56 : AppSizes.topbarHeight;
  double get sidebarWidth => atMost1280 ? 64 : AppSizes.sidebarWidth;
  double get layoutGap => 16;
  double get panelPad => atMost1100 ? 12 : 16;

  /// `clamp(300px, 24vw, 380px)` on POS, a fixed 310 elsewhere (KG-029).
  double summaryWidth({required bool isPos}) =>
      isPos ? _c.vw(300, 24, 380) : AppSizes.summaryWidthAlternate;

  // --- top bar ---------------------------------------------------------------
  double get rootFontSize => _c.vw(11, .85, 14);
  double get topbarPadX => _c.vw(10, 1, 20);
  double get topbarGap => atMost1280 ? 8 : _c.vw(8, .8, 16);
  double get brandGap => atMost1100 ? 6 : _c.vw(9, 1.25, 24);
  double get brandFont => atMost1100 ? 19 : _c.vw(19, 1.65, 26);
  double get brandMarkWidth => atMost1100 ? 28 : _c.vw(30, 3, 58);
  double get brandMarkFont => atMost1100 ? 30 : _c.vw(32, 2.7, 42);
  double get storeWidth => atMost1100 ? 160 : _c.vw(160, 15, 250);
  double get storeFont => _c.vw(11, .85, 14);
  double get searchHeight => _c.vh(36, 4.7, 44);
  double get searchMarginX => atMost1280 ? 3 : _c.vw(2, .8, 16);
  double get searchGap => atMost1280 ? 7 : 11;
  double get searchPadX => atMost1280 ? 8 : 13;
  double get searchFont => _c.vw(11, .85, 14);
  bool get showShortcutHint => !atMost1280;
  bool get showProfileText => !atMost1280;
  double get profilePadLeft => atMost1280 ? 8 : 10;
  double get profileGap => 8;
  double get avatarSize => _c.vw(30, 2.4, 38);

  // --- sidebar ---------------------------------------------------------------
  double get sidebarGap => _c.vh(8, 2.3, 24);
  double get sidebarButtonHeight => _c.vh(48, 8, 76);
  double get sidebarIconSize => _c.vw(21, 1.7, 26);
  double get sidebarLabelFont => _c.vw(10, .8, 13);

  // --- catalog and cart (consumed from S3) --------------------------------------
  double get emptyCustomerMarginBottom => _c.vh(8, 1.1, 13);
  double get emptyCustomerPaddingBottom => _c.vh(8, 1, 12);
  double get customerSelectWidth => _c.vw(105, 12, 175);
  double get customerSelectFont => _c.vw(11, .8, 13);
  double get saleTogglePadY => _c.vh(5, .8, 9);
  double get saleTogglePadX => _c.vw(6, .55, 10);
  double get categoryPadY => _c.vh(7, 1.1, 12);
  double get categoryPadX => _c.vw(8, .7, 13);
  double get subcategoriesMarginTop => _c.vh(8, 1.1, 12);
  double get subcategoryPadY => _c.vh(7, .9, 10);
  double get subcategoryPadX => _c.vw(8, .7, 13);
  double get catalogToolsMarginY => _c.vh(9, 1.4, 15);
  double get fieldHeight => _c.vh(32, 4.4, 42);
  double get fieldGap => _c.vw(5, .7, 11);
  double get fieldPadX => _c.vw(7, .8, 13);
  double get viewToggleWidth => _c.vw(26, 2.1, 36);
  double get viewToggleHeight => _c.vh(27, 3.5, 35);
  double get productGridMinColumn => _c.vw(130, 11, 170);
  double get productGridGap => _c.vw(6, .65, 11);
  double get productCardPad => _c.vw(7, .6, 11);
  double get productImageHeight => _c.vh(70, 9.6, 84);
  double get productPriceFont => _c.vw(12, .85, 15);
  double get productStepperButton => _c.vw(23, 1.8, 30);
  double get productStepperFirst => _c.vw(20, 1.6, 25);
  double get cartHeadingMinHeight => _c.vh(32, 4.5, 44);
  double get cartHeadingGap => _c.vw(5, .5, 9);
  double get cartHeadingFont => _c.vw(17, 1.25, 22);
  double get cartHeadingIcon => _c.vw(21, 1.7, 26);
  double get customerLabelMarginTop => _c.vh(7, 1, 12);
  double get cartTableMarginTop => _c.vh(8, 1.2, 13);
  double get cartLineMinHeight => _c.vh(84, 10, 96);
  double get statTileValueFont => _c.vw(20, 1.45, 28);

  // --- bill summary (consumed from S4) --------------------------------------------
  double get billSummaryPad => _c.vh(14, 1.6, 20);
  double get billSummaryGap => _c.vh(8, .75, 12);
  double get billSummaryTitleFont => _c.vw(18, 1.25, 22);
  double get summaryCardPad => _c.vh(6, .8, 10);
  double get summaryRowHeight => _c.vh(28, 3.2, 34);
  double get summaryRowValueFont => _c.vw(13, .95, 16);
  double get invoiceHeight => _c.vh(52, 5.6, 68);
  double get invoiceLabelFont => _c.vw(14, .9, 17);
  double get invoiceTotalFont => _c.vh(25, 2.5, 32);
  double get checkoutSectionPad => _c.vh(10, 1.3, 16);
  double get checkoutGap => _c.vh(8, .75, 12);
  double get paymentButtonHeight => _c.vh(46, 6.5, 56);
  double get paymentButtonFont => _c.vw(16, 1.1, 20);
  double get tenderedFont => _c.vw(18, 1.25, 22);
  double get quickActionTile => _c.vh(44, 5.2, 52);
}
