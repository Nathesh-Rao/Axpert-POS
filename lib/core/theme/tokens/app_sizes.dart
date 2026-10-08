// Token values trace to docs/css_metrics.md (cascade-resolved at the reference
// viewport); test/core/theme/css_metrics_test.dart asserts they match.

/// Fixed sizes in logical px, cascade-resolved. Fluid `clamp(vw/vh)` rules are not here (see AppMetrics in step 1.4b).
abstract final class AppSizes {
  /// --topbar-height (56 at <=1280)
  static const double topbarHeight = 64.0;

  /// --sidebar-width (64 at <=1280)
  static const double sidebarWidth = 80.0;

  /// --summary-width clamp(300px,24vw,380px) max; saturated at the reference viewport
  static const double summaryWidthMax = 380.0;

  /// --summary-width clamp min
  static const double summaryWidthMin = 300.0;

  /// .alternate-main !important (KG-029): non-POS pages
  static const double summaryWidthAlternate = 310.0;

  /// .modal
  static const double modalWidth = 460.0;

  /// .receipt-modal
  static const double receiptModalWidth = 530.0;

  /// .drawer
  static const double drawerWidth = 390.0;

  /// .toast
  static const double toastMinWidth = 290.0;

  /// .popover
  static const double popoverMinWidth = 170.0;

  /// .notifications
  static const double notificationsMinWidth = 290.0;

  /// .primary, .secondary
  static const double controlMinHeight = 43.0;

  /// .modal-input
  static const double modalInputHeight = 46.0;

  /// .qty-control (236)
  static const double qtyControlWidth = 144.0;

  /// .qty-control (236)
  static const double qtyControlHeight = 40.0;

  /// .qty-control button (236)
  static const double qtyButtonSize = 40.0;

  /// .qty-control input (236)
  static const double qtyInputWidth = 64.0;

  /// .line-edit
  static const double lineEditWidth = 76.0;

  /// .line-edit input (236)
  static const double lineEditHeight = 36.0;

  /// .cart-line .trash (236)
  static const double trashSize = 40.0;

  /// .cart-actions .action (236)
  static const double cartActionHeight = 44.0;

  /// .quick-actions .action min size (236)
  static const double quickActionMin = 44.0;

  /// .quick-actions .action>svg (236)
  static const double quickActionIcon = 22.0;

  /// .payment-buttons svg (236)
  static const double paymentIcon = 26.0;

  /// .complete-payment (236; 36/34 at height<=960/820)
  static const double completePaymentHeight = 48.0;

  /// .inline-tendered (236; 34/32 at height<=960/820)
  static const double inlineTenderedHeight = 44.0;

  /// .inline-payment .quick-amounts button (236)
  static const double quickAmountHeight = 36.0;

  /// .inline-terminal (236)
  static const double inlineTerminalHeight = 90.0;

  /// .inline-decline (236)
  static const double inlineDeclineHeight = 54.0;

  /// .currency-row>div (236)
  static const double currencyRowHeight = 40.0;

  /// .membership input/.field (236)
  static const double membershipFieldHeight = 38.0;

  /// .rate-label (236)
  static const double rateLabelHeight = 14.0;

  /// .bill-summary h2 (236)
  static const double billSummaryTitleHeight = 24.0;

  /// .line-product img (236)
  static const double cartLineImage = 48.0;

  /// cart-line first grid column (236)
  static const double cartLineCheckbox = 20.0;

  /// cart grid column 3 (236)
  static const double cartQtyColumn = 144.0;

  /// cart grid column 4 (236)
  static const double cartPriceColumn = 76.0;

  /// cart grid column 5 (236)
  static const double cartDiscountColumn = 76.0;

  /// cart grid column 6 minmax(80px,.8fr)
  static const double cartTotalMinColumn = 80.0;

  /// cart grid column 7 (236)
  static const double cartTrashColumn = 40.0;

  /// cart-line grid gap (236)
  static const double cartLineGap = 8.0;

  /// .cart-line margin-bottom (236)
  static const double cartLineMargin = 12.0;

  /// 1px solid var(--border) everywhere
  static const double borderWidth = 1.0;

  /// input:focus outline
  static const double focusRingWidth = 2.0;

  /// input:focus outline-offset
  static const double focusRingOffset = 2.0;

  /// .online i
  static const double onlineDot = 10.0;

  /// .catalog-footer .tiny-dot (dead: footer hidden)
  static const double tinyDot = 6.0;

  /// .notification-dot
  static const double notificationDot = 13.0;

  /// .discount-dot (236)
  static const double discountDot = 8.0;

  /// .quick-actions .small-badge (236)
  static const double smallBadgeQuick = 19.0;

  /// .product-stepper button max
  static const double productStepperBase = 30.0;

  /// .search-results top
  static const double searchResultsTop = 48.0;

  /// .popover top: calc(100% + 12px)
  static const double popoverOffset = 12.0;

  /// .toast-stack bottom
  static const double toastBottom = 23.0;

  /// .modal-overlay padding max
  static const double modalOverlayPad = 25.0;

  /// .modal padding max
  static const double modalPad = 32.0;

  /// .modal-symbol
  static const double modalSymbol = 57.0;

  /// .modal-overlay backdrop-filter blur
  static const double modalBlur = 4.0;

  /// .app min-height (dead: 236 screen block sets 0)
  static const double appMinHeight = 650.0;

  /// Decode width for product images (bounds memory with 10k products).
  static const double productImageCacheWidth = 256.0;

  /// `.categories button svg` and the category chip icon.
  static const double categoryIcon = 18.0;

  /// `.chip-next` min-width (screen block).
  static const double chipNextMinWidth = 26.0;

  /// `.chip-next svg` (ChevronRight size 20 in JSX).
  static const double chipNextIcon = 20.0;

  /// Search icon in `.field` (JSX size 19) and the clear button icon (15).
  static const double fieldSearchIcon = 19.0;
  static const double fieldClearIcon = 15.0;

  /// `.view-toggle` icons (JSX sizes 19 and 21).
  static const double viewGridIcon = 19.0;
  static const double viewListIcon = 21.0;

  /// Product card: favourite star (svg 15), stepper icons (16 and 19).
  static const double favouriteIcon = 15.0;
  static const double stepperMinusIcon = 16.0;
  static const double stepperPlusIcon = 19.0;

  /// `.product-list .product-image` (screen block).
  static const double productListImageWidth = 45.0;
  static const double productListImageHeight = 54.0;

  /// `.no-results` search icon (JSX size 32).
  static const double noResultsIcon = 32.0;

  /// Height of the `.empty-customer` row content until the S4 customer chip
  /// exists (measured from the reference screenshot: chip row about 36 px).
  static const double emptyCustomerRowHeight = 36.0;

  /// Thin scrollbar (`scrollbar-width: thin`) thumb thickness.
  static const double scrollbarThickness = 8.0;

  /// Cart table icons: `.qty-control button svg` (JSX 20), trash (20), the
  /// action button and heading icons come from AppMetrics.
  static const double qtyButtonIcon = 20.0;
  static const double trashIcon = 20.0;

  /// `.cart-line .line-product img` radius (8) and gap between its parts.
  static const double cartLineImageRadius = 8.0;

  /// `.cart-table-head` padding 10 x 12 and `.cart-line` padding 12.
  static const double cartHeadPadY = 10.0;
  static const double cartPad = 12.0;

  /// `.line-edit input` height uses lineEditHeight; its text is 14.
  /// `.stat-tiles` padding and gap (the later block), tile padding 16 x 8.
  static const double statTilesPad = 12.0;
  static const double statTilesGap = 12.0;
  static const double statTilePadY = 16.0;
  static const double statTilePadX = 8.0;
  static const double statTileGap = 8.0;

  /// `.cart-actions` gap and top margin.
  static const double cartActionsGap = 10.0;
  static const double cartActionsMarginTop = 12.0;

  /// Stacked cart line (width <= 1700): quantity control 152 x 44, inputs 44.
  static const double qtyControlStackedWidth = 152.0;
  static const double qtyControlStackedHeight = 44.0;
  static const double lineEditStackedHeight = 44.0;
  static const double lineEditStackedMaxWidth = 76.0;

  /// Stacked line geometry: first row min height, row and column gaps, the
  /// product block's side paddings, and the absolutely placed number, total
  /// and trash (offsets from the line's padding box).
  static const double stackedRow1MinHeight = 52.0;
  static const double stackedRowGap = 12.0;
  static const double stackedColumnGap = 8.0;
  static const double stackedProductPadLeft = 20.0;
  static const double stackedProductPadRight = 120.0;
  static const double stackedNumberLeft = 12.0;
  static const double stackedNumberTop = 18.0;
  static const double stackedTotalRight = 60.0;
  static const double stackedTotalTop = 23.0;
  static const double stackedTrashRight = 12.0;
  static const double stackedTrashTop = 12.0;

  /// `.control-label` above the stacked controls: 12 px, line 14, margin 4.
  static const double controlLabelLineHeight = 14.0;
  static const double controlLabelGap = 4.0;

  /// Stacked cart actions: icon above the label, height unchanged.
  static const double cartActionStackedIconGap = 3.0;

  /// All values by name, for the css_metrics tests.
  static const Map<String, num> all = <String, num>{
    'topbarHeight': topbarHeight,
    'sidebarWidth': sidebarWidth,
    'summaryWidthMax': summaryWidthMax,
    'summaryWidthMin': summaryWidthMin,
    'summaryWidthAlternate': summaryWidthAlternate,
    'modalWidth': modalWidth,
    'receiptModalWidth': receiptModalWidth,
    'drawerWidth': drawerWidth,
    'toastMinWidth': toastMinWidth,
    'popoverMinWidth': popoverMinWidth,
    'notificationsMinWidth': notificationsMinWidth,
    'controlMinHeight': controlMinHeight,
    'modalInputHeight': modalInputHeight,
    'qtyControlWidth': qtyControlWidth,
    'qtyControlHeight': qtyControlHeight,
    'qtyButtonSize': qtyButtonSize,
    'qtyInputWidth': qtyInputWidth,
    'lineEditWidth': lineEditWidth,
    'lineEditHeight': lineEditHeight,
    'trashSize': trashSize,
    'cartActionHeight': cartActionHeight,
    'quickActionMin': quickActionMin,
    'quickActionIcon': quickActionIcon,
    'paymentIcon': paymentIcon,
    'completePaymentHeight': completePaymentHeight,
    'inlineTenderedHeight': inlineTenderedHeight,
    'quickAmountHeight': quickAmountHeight,
    'inlineTerminalHeight': inlineTerminalHeight,
    'inlineDeclineHeight': inlineDeclineHeight,
    'currencyRowHeight': currencyRowHeight,
    'membershipFieldHeight': membershipFieldHeight,
    'rateLabelHeight': rateLabelHeight,
    'billSummaryTitleHeight': billSummaryTitleHeight,
    'cartLineImage': cartLineImage,
    'cartLineCheckbox': cartLineCheckbox,
    'cartQtyColumn': cartQtyColumn,
    'cartPriceColumn': cartPriceColumn,
    'cartDiscountColumn': cartDiscountColumn,
    'cartTotalMinColumn': cartTotalMinColumn,
    'cartTrashColumn': cartTrashColumn,
    'cartLineGap': cartLineGap,
    'cartLineMargin': cartLineMargin,
    'borderWidth': borderWidth,
    'focusRingWidth': focusRingWidth,
    'focusRingOffset': focusRingOffset,
    'onlineDot': onlineDot,
    'tinyDot': tinyDot,
    'notificationDot': notificationDot,
    'discountDot': discountDot,
    'smallBadgeQuick': smallBadgeQuick,
    'productStepperBase': productStepperBase,
    'searchResultsTop': searchResultsTop,
    'popoverOffset': popoverOffset,
    'toastBottom': toastBottom,
    'modalOverlayPad': modalOverlayPad,
    'modalPad': modalPad,
    'modalSymbol': modalSymbol,
    'modalBlur': modalBlur,
    'appMinHeight': appMinHeight,
  };
}
