import 'en_app_strings.dart';

/// All user-facing strings (English only for now). One method per message,
/// named parameters, values pre-formatted by the caller, no concatenation in
/// views. Method names are the future ARB keys, so `gen_l10n` can replace this
/// class with the same signatures (DEC-034).
abstract class AppStrings {
  const AppStrings();

  /// The active strings. Swapped when translations arrive.
  static AppStrings current = const EnAppStrings();

  String appTitle();

  // Navigation and pages
  String navPos();
  String navProducts();
  String navCustomers();
  String navSales();
  String navReturns();
  String navReports();
  String navMore();
  String titleSettings();
  String workspaceEyebrow();

  // Top bar
  String brandMark();
  String brandName();
  String storeNameOzone();
  String storeNameCentral();
  String storeNameMarina();
  String storeSelectLabel();
  String searchHint();
  String searchShortcutMac();
  String searchShortcutOther();
  String scanTooltip();
  String online();
  String offline();
  String notificationsTooltip();
  String notificationsTitle();
  String notificationLowStock();
  String notificationSynced();
  String notificationHeld({required int count});
  String moreOptionsTooltip();
  String userInitial();
  String userName();
  String userRole();
  String menuProfile();
  String menuSettings();
  String menuShortcuts();
  String menuLogout();

  // Feedback and placeholders
  String storeSwitched();
  String placeholderDialogBody();
  String dialogClose();
  String dialogCloseTooltip();
  String confirmTitle();
  String confirmCancel();
  String confirmAccept();
  String confirmClearCart();

  // Frame, toasts
  String billSummaryTitle();
  String offlineBanner();
  String toastDismissTooltip();
  String toastUndo();

  // Catalog
  String catalogCaptionTitle();
  String catalogCaptionCount(int count);
  String categoryAllItems();
  String categoryFavourites();
  String subcategoryAll();
  String moreCategoriesTooltip();
  String searchProductHint();
  String clearSearchTooltip();
  String gridViewTooltip();
  String listViewTooltip();
  String favouriteTooltip();
  String addProductTooltip(String name);
  String removeOneTooltip(String name);
  String qtyBadge(String qty);
  String placeholderJuiceTag();
  String placeholderCareTag();
  String noResultsTitle();
  String noResultsHint();
  String resetFilters();

  // Cart
  String cartTableNumber();
  String lineNumber(int number);
  String cartTableItem();
  String cartTableQty();
  String cartTablePrice();
  String cartTableDiscount();
  String cartTableTotal();
  String decreaseQtyTooltip();
  String increaseQtyTooltip();
  String qtyInputLabel(String name);
  String priceInputLabel(String name);
  String discountInputLabel(String name);
  String removeItemTooltip();
  String gstLabel(String percent);
  String actionClearCart();
  String actionHold();
  String actionRecall();
  String actionPriceCheck();
  String statTotalItems();
  String statTotalQty();
  String statTotalValue();

  // Cart and catalog toasts
  String toastProductAdded(String name);
  String toastProductRemoved(String name);
  String toastStockAvailable(int stock);
  String toastStockOnly(int stock);

  // Shortcuts (demo until S3/S4) and settings toggles
  String shortcutDemo({required String action});
  String shortcutCash();
  String shortcutCard();
  String shortcutHold();
  String shortcutRecall();
  String shortcutDiscount();
  String darkModeTitle();
  String darkModeHint();
  String beepTitle();
  String beepHint();

  // S4.a checkout
  String summarySubtotal();
  String summaryDiscount();
  String summaryRewardPoints();
  String summaryTaxAmount();
  String summaryInvoiceTotal();
  String forexFc();
  String forexRateLabel();
  String forexCurrencySemantic();
  String forexRateSemantic();
  String forexCurrencyLabel(String code);
  String memberNumberLabel();
  String memberNumberHint();
  String memberFindTooltip();
  String memberInfoLabel();
  String memberPointsAvailable();
  String memberPointsRedeem();
  String memberCompactTitle();
  String memberAdd();
  String payCash();
  String paySaveCredit();
  String payCard();
  String amountDue();
  String amountTendered();
  String amountTenderedHint();
  String quickAmountExact();
  String changeDue();
  String completePayment();
  String saveOnCredit();
  String terminalAddItems();
  String terminalWaiting();
  String terminalApproved();
  String terminalDeclined();
  String simulateDecline();
  String terminalRetry();
  String actionDiscount();
  String actionClearHold();
  String actionReprint();
  String actionClear();
  String actionClose();
  String actionTitleWithKey({required String label, required String key});
  String saleCash();
  String saleCredit();
  String customerLabel();
  String customerFindTooltip();
  String customerSearchTooltip();
  String addCustomerButton();
  String addCustomerTooltip();
  String creditValidation();
  String orderNote(String note);
  String orderOptionsTooltip();
  String orderRename();
  String orderAddNote();
  String orderPrintDraft();
  String toastWelcome(String name);
  String toastMemberNotFound();
  String toastCreditNeedsCustomer();
  String toastStockChanged();
  String toastPaymentCompleted();
  String toastSavedOnCredit();
  String confirmSaveCredit({required String total, required String customer});
  String confirmDeleteHeld({required int count});
  String toastHeldCleared();
  String countBadge(int count);
  String toastAddItemsBeforeHold();
  String toastBillHeld();
  String toastBillRecalled(String ref);
  String heldBillsTitle();
  String heldBillsSubtitle();
  String heldBillRowTitle(String ref, int items);
  String heldBillsEmpty();
  String recallConflictTitle();
  String recallConflictBody(String ref);
  String recallReplaceCurrent();
  String recallHoldAndRecall();
  String discountDrawerTitle();
  String discountDrawerSubtitle();
  String discountTabPercent();
  String discountTabFlat();
  String discountValueLabel();
  String discountReasonLabel();
  String discountReasonHint();
  String discountRemove();
  String discountApply();
  String toastProductNotFoundForBarcode(String barcode);
  String toastProductNotFound();
  String toastCustomerAdded();
  String toastCustomerInvalid();
  String scanDialogTitle();
  String scanDialogBody();
  String scanInputHint();
  String scanRandom();
  String scanSimulate();
  String scanTryHint();
  String priceCheckBody();
  String priceCheckHint();
  String priceCheckNoMatch();
  String priceCheckDetails(String code, int stock, String gst);
  String customerPickerTitle();
  String customerPickerHint();
  String customerRowDetail(String phone, String member, int points);
  String customerAddButton();
  String addCustomerTitle();
  String addCustomerBody();
  String addCustomerName();
  String addCustomerPhone();
  String addCustomerEmail();
  String addCustomerSave();
  String searchResultsLabel();
}
