import 'dart:ui' show Size;

import '../theme/tokens/app_sizes.dart';
import 'breakpoints.dart';
import 'clamp_rule.dart';
import 'summary_metrics.dart';

export 'summary_metrics.dart' show SummaryDensity;

enum CartLineLayout { single, stacked }

/// One column of the cart table: a fixed [width] or a flexible share [flex]
/// (`minmax(0, N fr)` is [flex] = 10 x N).
typedef CartColumn = ({double? width, int flex});

/// Header columns and gap (`.cart-table-head` grid).
class CartHeaderColumns {
  const CartHeaderColumns(this.columns, this.gap);

  /// `20px 1.6fr 144px 76px 76px .8fr 40px`, gap 8.
  static const CartHeaderColumns wide = CartHeaderColumns(<CartColumn>[
    (width: 20, flex: 0),
    (width: null, flex: 16),
    (width: 144, flex: 0),
    (width: 76, flex: 0),
    (width: 76, flex: 0),
    (width: null, flex: 8),
    (width: 40, flex: 0),
  ], 8);

  /// `18px 1.4fr 1.3fr .8fr .8fr 1fr 0`, gap 4 (width <= 1700).
  static const CartHeaderColumns stacked = CartHeaderColumns(<CartColumn>[
    (width: 18, flex: 0),
    (width: null, flex: 14),
    (width: null, flex: 13),
    (width: null, flex: 8),
    (width: null, flex: 8),
    (width: null, flex: 10),
    (width: 0, flex: 0),
  ], 4);

  final List<CartColumn> columns;
  final double gap;
}

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

  /// `.management` padding, `clamp(16px, 1.5vw, 28px)`.
  double get managementPad => _c.vw(16, 1.5, 28);
  double get modalOverlayPad => _c.vw(12, 2, 25);
  double get modalPad => _c.vw(20, 2, 32);

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
  double get productPriceFont => atMost1100 ? 11 : _c.vw(12, .85, 15);
  double get productStepperGap => atMost1100 ? 2 : 3;
  double get productStepperButton => _c.vw(23, 1.8, 30);
  double get productStepperFirst => _c.vw(20, 1.6, 25);

  /// `clamp(12px,.82vw,14px)`: field input, product name, category and
  /// subcategory chip text (the later screen block wins over the clamp(10..13)
  /// block).
  double get catalogFont => _c.vw(12, .82, 14);

  /// `.product-list .product-name`, `clamp(11px,.85vw,14px)`.
  double get productListNameFont => _c.vw(11, .85, 14);

  /// Product code (`.product-info > small`), 12 in the later block.
  double get productCodeFont => 12;

  /// Chip heights: vertical padding twice plus the 1.5 line height (the
  /// category icon, 18, is smaller than the line).
  double get categoryChipHeight => 2 * categoryPadY + catalogFont * 1.5;
  double get subcategoryChipHeight => 2 * subcategoryPadY + catalogFont * 1.5;

  /// Grid card: border, padding, image (margins 4 and 8), name line plus 4,
  /// code line, 5 gap and the stepper row.
  double get productCardHeight =>
      2 +
      2 * productCardPad +
      4 +
      productImageHeight +
      8 +
      catalogFont * 1.5 +
      4 +
      productCodeFont * 1.5 +
      5 +
      productStepperButton;

  /// `.product-list .product-card` height, `clamp(72px,9vh,90px)`.
  double get productListCardHeight => _c.vh(72, 9, 90);

  /// `.cart-heading` min-height: 30 at height <= 820 (the later rule wins).
  double get cartHeadingMinHeight => heightAtMost820 ? 30 : _c.vh(32, 4.5, 44);

  /// 5 at width <= 1280.
  double get cartHeadingGap => atMost1280 ? 5 : _c.vw(5, .5, 9);

  /// Counter and icon: 16 / 19 at width <= 1100.
  double get cartHeadingFont => atMost1100 ? 16 : _c.vw(17, 1.25, 22);
  double get cartHeadingIcon => atMost1100 ? 19 : _c.vw(21, 1.7, 26);

  /// At width <= 1280 the clock wraps to its own full-width row
  /// (`order:5; flex:1 0 100%; padding:2px 0`).
  bool get cartTimeOnOwnRow => atMost1280;
  double get customerLabelMarginTop => _c.vh(7, 1, 12);
  double get cartTableMarginTop => _c.vh(8, 1.2, 13);
  double get cartLineMinHeight => _c.vh(84, 10, 96);

  /// Value font of a stat tile: `clamp(20,1.45vw,28)`, and
  /// `clamp(18,1.5vw,24)` at width <= 1700 (the <= 1100 16 px rule is dead).
  double get statTileValueFont =>
      atMost1700 ? _c.vw(18, 1.5, 24) : _c.vw(20, 1.45, 28);

  /// `.cart-actions .action svg`, `clamp(14px,1.2vw,19px)`.
  double get cartActionIcon => _c.vw(14, 1.2, 19);

  /// `.stat-tiles svg`, `clamp(19px,1.8vw,26px)` (the later block wins over 25).
  double get statTileIcon => atMost1700 ? 21 : _c.vw(19, 1.8, 26);

  /// Stat tiles at width <= 1100: no icon, vertical tiles.
  bool get showStatTileIcon => !atMost1100;
  bool get statTilesVertical => atMost1100;
  double get statTilesPad => atMost1100 ? 8 : 12;
  double get statTilesGap => atMost1100 ? 8 : 12;
  double get statTilePadY => atMost1100 ? 12 : (atMost1700 ? 14 : 16);
  double get statTilePadX => atMost1700 ? 5 : 8;
  double get statTileGap => atMost1700 ? 5 : 8;

  /// Cart actions at width <= 1700: icon above the label, gap 3.
  bool get cartActionsStacked => atMost1700;
  double get cartActionsStackedGap => 3;

  /// Cart line (see [CartLineLayout]): quantity control and inputs.
  bool get lineStacked => cartLineLayout == CartLineLayout.stacked;
  double get qtyControlWidth =>
      lineStacked ? AppSizes.qtyControlStackedWidth : AppSizes.qtyControlWidth;
  double get qtyControlHeight => lineStacked
      ? AppSizes.qtyControlStackedHeight
      : AppSizes.qtyControlHeight;
  double get qtyButtonSize =>
      lineStacked ? AppSizes.qtyControlStackedHeight : AppSizes.qtyButtonSize;
  double get lineEditHeight =>
      lineStacked ? AppSizes.lineEditStackedHeight : AppSizes.lineEditHeight;

  /// Price and discount text: 14, 13 at width <= 1100.
  double get lineEditFont => atMost1100 ? 13 : 14;

  /// Line number text: 13, 12 when stacked.
  double get lineNumberFont => lineStacked ? 12 : 13;

  /// Product image and barcode hide at width <= 1100 (the <= 1280 rules are
  /// overridden by later ones); the GST line always stays.
  bool get showLineImage => !atMost1100;
  bool get showLineBarcode => !atMost1100;

  /// Table header columns for the current layout (`.cart-table-head`). In the
  /// wide layout they equal the line's columns; at width <= 1700 the header
  /// keeps its own six columns while lines stack, as in the prototype.
  CartHeaderColumns get cartHeaderColumns =>
      lineStacked ? CartHeaderColumns.stacked : CartHeaderColumns.wide;

  /// Height <= 719: the member card collapses.
  bool get memberCollapsed => heightAtMost719;

  /// Bill Summary values for the current density (used from S4.a).
  SummaryMetrics get summary => SummaryMetrics.of(summaryDensity, _c);

  /// With the cart open and width <= 1280 the catalog grid has exactly 2
  /// columns (`repeat(2, minmax(0,1fr))`); otherwise auto-fill.
  int? catalogFixedColumns({required bool cartOpen, required bool list}) =>
      atMost1280 && cartOpen && !list ? 2 : null;

  /// `.cart-line` min-height in the single-row layout, `clamp(84px,10vh,96px)`
  /// (already `cartLineMinHeight`).
  /// `.cart-heading time`, `clamp(9px,.7vw,12px)` overridden by the later 12.
  double get cartTimeFont => 12;

  // --- bill summary (consumed from S4) --------------------------------------------
  double get billSummaryPad => summary.panelPad;
  double get billSummaryGap => summary.gap;
  double get billSummaryTitleFont => summary.titleFont;
  double get summaryCardPad => summary.cardPad;
  double get summaryRowHeight => summary.rowHeight;
  double get summaryRowValueFont => summary.rowValueFont;
  double get invoiceHeight => summary.invoiceHeight;
  double get invoiceLabelFont => summary.invoiceLabelFont;
  double get invoiceTotalFont => summary.invoiceTotalFont;
  double get checkoutSectionPad => summary.checkoutPad;
  double get checkoutGap => summary.checkoutGap;
  double get paymentButtonHeight => summary.paymentButtonHeight;
  double get paymentButtonFont => summary.paymentButtonFont;
  double get tenderedFont => _c.vw(18, 1.25, 22);
  double get quickActionTile => summary.quickActionSize;
}
