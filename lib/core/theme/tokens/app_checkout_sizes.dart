/// Fixed sizes of the Bill Summary checkout parts and the cart customer row
/// (`css_metrics.md` sections 8 and 13; fluid sizes come from `AppMetrics`).
abstract final class AppCheckoutSizes {
  /// `.summary-card` border
  static const double cardBorder = 1.0;

  /// `.payment-buttons button` border (236)
  static const double payButtonBorder = 1.5;
  static const double payButtonGap = 10.0;
  static const double disabledPayOpacity = 0.55;
  static const double disabledOpacity = 0.45;

  /// `.inline-amount b`, `.change-due b`
  static const double inlineValueFont = 18.0;
  static const double inlineLabelFont = 13.0;
  static const double inlineTenderedGap = 7.0;
  static const int tenderedLabelFlex = 10;
  static const int tenderedInputFlex = 11;
  static const double quickAmountGap = 8.0;

  /// `.inline-terminal` (236)
  static const double terminalPad = 12.0;
  static const double terminalPadSmall = 6.0;
  static const double terminalGap = 7.0;
  static const double terminalIcon = 24.0;
  static const double terminalFont = 15.0;
  static const double terminalAmountFont = 21.0;
  static const double spinnerSize = 17.0;
  static const double spinnerStroke = 3.0;
  static const double declineCheckbox = 22.0;
  static const double cardOptionsGap = 8.0;
  static const double retryHeight = 32.0;
  static const double retryFont = 12.0;
  static const double retryPadX = 8.0;

  /// `.rate-label input`
  static const double rateInputWidth = 50.0;
  static const double rateGap = 7.0;
  static const double rateMarginTop = 4.0;

  /// `.currency-row > div`
  static const double currencyGap = 10.0;
  static const double currencyPad = 8.0;
  static const double currencyPadSmall = 3.0;
  static const double currencyInnerGap = 6.0;
  static const double currencySelectMaxWidth = 53.0;

  /// `.membership input`
  static const double memberInputPadX = 9.0;
  static const double memberIcon = 19.0;
  static const double memberLabelLineTight = 12.0;
  static const double memberDisabledOpacity = 0.7;

  /// `.invoice` margin-top
  static const double invoiceMarginTop = 4.0;

  /// `.quick-actions`
  static const double quickActionRadius = 12.0;
  static const double badgeSize = 19.0;
  static const double badgeFont = 11.0;
  static const double badgeBorder = 2.0;
  static const double badgeOffset = -3.0;
  static const double dotRight = 7.0;
  static const double dotTop = 6.0;
  static const double dotRing = 2.0;
  static const double clockSize = 11.0;
  static const double clockRight = 9.0;
  static const double clockBottom = 10.0;

  /// `.sale-toggle`
  static const double radioSize = 11.0;
  static const double radioBorder = 1.5;
  static const double radioBorderChosen = 3.0;
  static const double saleToggleGap = 6.0;
  static const double saleToggleFont = 12.0;
  static const double saleToggleInnerGap = 6.0;

  /// `.customer-row`
  static const double customerRowGap = 10.0;
  static const double customerRowIcon = 20.0;
  static const double customerFieldPadX = 11.0;
  static const double customerFieldGap = 11.0;
  static const double customerLabelFont = 12.0;
  static const double customerLabelMarginBottom = 7.0;
  static const double addCustomerPadX = 11.0;
  static const double addCustomerFont = 12.0;
  static const double addCustomerIcon = 19.0;
  static const double addCustomerIconSmall = 14.0;
  static const double addCustomerFontSmall = 10.0;
  static const double customerFindIcon = 19.0;
  static const double validationFont = 11.0;
  static const double validationMarginTop = 8.0;
  static const double noteFont = 11.0;
  static const double noteMarginTop = 8.0;

  /// `.customer-chip` (empty-cart catalog header)
  static const double chipPadX = 10.0;
  static const double chipPadY = 8.0;
  static const double chipGap = 8.0;
  static const double chipIcon = 17.0;
  static const double chipSearchIcon = 16.0;
  static const double headerGap = 14.0;
  static const double headerAddIcon = 19.0;
  static const double orderMenuIcon = 20.0;

  /// `.drawer`, `.modal-symbol`, `.segmented`, `.form-label` (S4.b)
  static const double drawerPadTop = 45.0;
  static const double symbolIcon = 27.0;
  static const double symbolMarginBottom = 18.0;
  static const double segmentedPad = 4.0;
  static const double segmentedGap = 4.0;
  static const double segmentedButtonPad = 11.0;
  static const double formLabelMarginTop = 15.0;
  static const double formLabelFont = 13.0;
  static const double formInputGap = 9.0;
  static const double formInputMarginBottom = 10.0;
  static const double formInputPadX = 13.0;
  static const double formInputPadY = 10.0;
  static const double modalParagraphMarginBottom = 20.0;

  /// `.modal-list`, `.empty-state`
  static const double modalListMaxHeight = 400.0;
  static const double modalListMaxHeightFraction = 0.4;
  static const double modalListMarginY = 20.0;
  static const double modalListRowPadY = 17.0;
  static const double modalListRowPadX = 8.0;
  static const double modalListRowGap = 12.0;
  static const double modalListIcon = 23.0;
  static const double modalListSmallMarginTop = 6.0;
  static const double modalListSmallFont = 12.0;
  static const double emptyStatePadY = 45.0;
  static const double emptyStatePadX = 15.0;
  static const double emptyStateGap = 12.0;
  static const double emptyStateIcon = 32.0;

  /// `.modal-input` standing alone (scan, price check, customer search)
  static const double modalInputMarginTop = 9.0;
  static const double modalInputMarginBottom = 20.0;

  /// `.primary` with an icon, `.primary.full`
  static const double primaryIconGap = 8.0;
  static const double primaryPlusIcon = 17.0;
  static const double primaryFullMarginTop = 12.0;

  /// `.modal-symbol` icon of the scan dialog
  static const double scanSymbolIcon = 30.0;

  /// `.price-result`: h3 is the UA 1.17 em of the 14 px base.
  static const double priceResultPad = 25.0;
  static const double priceResultMarginTop = 20.0;
  static const double priceResultNameFont = 16.38;
  static const double priceResultPriceMarginY = 12.0;

  /// `.modal-list` rows of the customer picker
  static const double pickerUserIcon = 22.0;
  static const double pickerChevron = 18.0;

  /// `.search-results`
  static const double searchResultsTop = 48.0;
  static const double searchResultsPad = 6.0;
  static const double searchResultRowPad = 11.0;
  static const double searchResultSmallFont = 12.0;

  /// `.receipt*` (the compact `@media screen` values apply at every size)
  static const double receiptBrandMarginBottom = 8.0;
  static const double receiptStoreFont = 18.0;
  static const double receiptStoreMarginBottom = 6.0;
  static const double receiptTaglineFont = 12.0;
  static const double receiptMetaPadY = 10.0;
  static const double receiptMetaMarginY = 12.0;
  static const double receiptMetaGap = 4.0;
  static const double receiptMetaFont = 11.0;
  static const double receiptMetaLineHeight = 1.3;
  static const double receiptTableFont = 12.0;
  static const double receiptThPadY = 8.0;
  static const double receiptTdPadY = 9.0;
  static const double receiptItemsMaxFraction = 0.26;
  static const double receiptItemsMinHeight = 100.0;
  static const double receiptTotalsMarginTop = 10.0;
  static const double receiptTotalsPadTop = 6.0;
  static const double receiptRowPadY = 4.0;
  static const double receiptRowFont = 12.0;
  static const double receiptRowLineHeight = 1.3;
  static const double receiptGrandFont = 20.0;
  static const double receiptGrandMarginTop = 4.0;
  static const double receiptGrandPadY = 7.0;
  static const double receiptThanksMarginY = 10.0;
  static const double receiptActionsGap = 6.0;
  static const double receiptActionsMarginTop = 20.0;
  static const double receiptActionFont = 12.0;
  static const double receiptActionPad = 10.0;
  static const double receiptActionIcon = 17.0;
  static const double dashLength = 3.0;
  static const double dashGap = 3.0;

  /// `.shortcut`, `.shortcut kbd`
  static const double shortcutRowPadY = 13.0;
  static const double kbdPadX = 8.0;
  static const double kbdPadY = 3.0;
  static const double kbdFont = 12.0;
}
