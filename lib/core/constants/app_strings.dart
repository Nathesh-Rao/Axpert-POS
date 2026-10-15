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

  // Splash and login (demo entry flow, no real authentication)
  String splashSemantics();
  String loginWelcome();
  String loginSubtitle();
  String loginUsernameLabel();
  String loginUsernameHint();
  String loginPasswordLabel();
  String loginPasswordHint();
  String loginUsernameRequired();
  String loginPasswordRequired();
  String loginShowPassword();
  String loginHidePassword();
  String loginRememberMe();
  String loginForgotPassword();
  String loginSignIn();
  String loginSigningIn();
  String loginOr();
  String loginWithQr();
  String loginNoAccount();
  String loginLanguage();
  String loginDemoToast(String feature);

  // Top bar
  String brandMark();
  String brandName();
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

  /// Between the barcode and the tax rate on the second line of a cart row.
  String cartInfoSeparator();

  /// Tooltip of a footer action with its key: `Hold (F4)`.
  String actionWithKey(String action, String key);
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

  /// `GST 18%` / `VAT 18%`; empty when the store has no tax regime.
  String taxRateLabel(String label, String percent);
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
  String exportDbTitle();
  String exportDbHint();
  String exportDbButton();
  String exportDbExporting();
  String exportDbConfirm();
  String exportDbSavedFile(String path);
  String exportDbDownloaded(String fileName);
  String exportDbFailed();
  String exportDbCopy();
  String exportDbPathCopied();

  // S4.a checkout
  String summarySubtotal();
  String summaryDiscount();
  String summaryRewardPoints();

  /// Tax row of the Bill Summary: `GST Amount`, `VAT Amount`.
  String summaryTaxAmount(String label);
  String summaryInvoiceTotal();
  String forexRateLabel();
  String forexCurrencySemantic();
  String forexRateSemantic();
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
  String toastStockNegative();
  String toastPaymentMethodOff();
  String toastPaymentCompleted();
  String toastPaymentFailed();
  String toastSaveFailed();
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
  String discountTabFlat(String symbol);

  // Offers (automatic discounts, Buy 1 Get 1, free items)
  String offerBadgePercent(String percent);
  String offerBadgeAmount(String amount);
  String offerBadgeBogo();
  String offerBadgeGift();
  String offerSaved(String name, String amount);
  String giftLockedHint(String amount);
  String giftFreeLabel(String name);
  String giftFreePrice();
  String giftLockedSemantics(String product);
  String giftUnlockedSemantics(String product);

  // Sign-in against the database, store and counter pickers
  String loginInvalid();
  String loginNoAccess();
  String loginNoUsers();
  String loginNoUsersHint();
  String pickerTitle();
  String pickerSubtitle();
  String pickerStoreLabel();
  String pickerCounterLabel();
  String pickerContinue();
  String pickerSignedInAs(String name, String role);
  String storeNone();
  String counterNone();
  String toastSwitchStoreCartNotEmpty();
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
  String priceCheckDetails(String code, int stock, String taxRate);
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
  String receiptBrand();
  String receiptTagline();
  String receiptBill(String number);
  String receiptCashier(String name);
  String receiptCustomer(String name);
  String receiptColItem();
  String receiptColQty();
  String receiptColTotal();
  String receiptSubtotal();
  String receiptDiscount();
  String receiptPoints();
  String receiptTotal();
  String receiptPayment();
  String receiptChange();
  String receiptThanks();
  String receiptPrint();
  String receiptEmail();
  String receiptWhatsApp();
  String receiptNewSale();
  String toastPrintUnavailable();
  String toastPrintFailed();
  String toastReceiptEmail();
  String toastReceiptWhatsApp();
  String reprintTitle();
  String reprintSubtitle();
  String reprintRowTitle(String number, String customer);
  String reprintEmpty();
  String noteDialogTitle();
  String textDialogSave();
  String shortcutsTitle();
  String helpFocusSearch();
  String helpToggleProducts();
  String productsShortcutMac();
  String productsShortcutOther();

  /// The edge tab of the desktop POS page (DEC-139).
  String productsTabLabel();
  String workTabCart(int count);
  String workTabBadge(int count);
  String workTabToCartSemantic(int count, String shortcut);
  String workTabToProductsSemantic(String shortcut);
  String workTabEmptySemantic();

  /// Edge control of the three-panel layout (DEC-141). [state] is
  /// `productsStepLabel`.
  String productsStepLabel(int percent);
  String workTabResizeSemantic(String state, String shortcut);
  String workTabWiderSemantic(String state);
  String workTabNarrowerSemantic(String state);

  /// Billing collapse button, footer chip and shortcut row.
  String helpToggleBilling();
  String billingShortcutMac();
  String billingShortcutOther();
  String billingCollapseTooltip(String shortcut);
  String billingChipSemantic(String total);
  String billingChipTooltip(String shortcut);
  String helpAddScanned();
  String helpRemoveLine();
  String helpCloseDialog();
  String keyEnter();
  String keyDelete();
  String keyEscape();
  String keyFunction(int number);
  String searchPageHint(String page);
  String pageNameProducts();
  String pageNameCustomers();
  String pageNameSales();
  String colProduct();
  String colCodeBarcode();
  String colCategory();

  /// Tax column heading of the products table (`GST`, `VAT`).
  String colTax(String label);
  String colPrice();
  String colStock();
  String colName();
  String colPhone();
  String colEmail();
  String colMembership();
  String colPoints();
  String emptyCell();
  String percentSuffix(String value);
  String colBill();
  String colDate();
  String colCustomer();
  String colMode();
  String colTotal();
  String salesViewReceipt();
  String salesEmptyTitle();
  String salesEmptyBody();
  String reportsTodaySales();
  String reportsBillsCompleted();
  String reportsAverageBill();
  String reportsByMode();
  String reportsBasedOn(String date);
  String closeTitle();
  String closeIntro();
  String closeTotalSales();
  String closeBills();
  String closeNote();
  String closeConfirm();
  String signedOutTitle();
  String signedOutBody();
  String signedOutStart();
  String profileRole(String store);
  String profileCounter();
  String roleLabel(String role);
  String profileShiftSales();
  String profileStatus();
  String returnsFindTitle();
  String returnsBillHint();
  String returnsBegin();
  String returnsNoMatch();
  String returnsBillSummary(String customer, String total);
  String returnsAvailable(String qty);
  String returnsRefundButton();
  String returnsQtyLabel(String product);
  String toastRefundSelect();
  String toastRefundExceeds();
  String toastRefundDone(String amount);
  String refundConfirm(String amount);

  // Product management (DEC-152)
  String productAddButton();
  String productShowInactive();
  String productEditAction();
  String productDeactivateAction();
  String productReactivateAction();
  String productInactiveBadge();
  String colProductActions();
  String stockPart(String qty, String unit);
  String stockPartsJoin();
  String stockNegativeMark();
  String productFormAddTitle();
  String productFormEditTitle();
  String productFieldName();
  String productFieldSku();
  String productFieldCategory();
  String productFieldSubCategory();
  String productFieldBrand();
  String productFieldBaseUnit();
  String productFieldPrice(String currency);
  String productFieldTax(String label);
  String productFieldBarcodes();
  String productBarcodeAddHint();
  String productFieldActive();
  String productNone();
  String productNewInline();
  String productNewCategoryHint();
  String productNewBrandHint();
  String productSectionPackaging();
  String productPackagingAdd();
  String productPackagingRemove();
  String productPackagingUnit();
  String productPackagingContains(String base);
  String productPackagingSku();
  String productPackagingBarcode();
  String productPackagingPrice();
  String productPackagingEnabled();
  String productPackagingPreview(
    String unit,
    String qty,
    String base,
    String price,
  );
  String productPackagingDerived();
  String productSectionStock();
  String productOpeningStock();
  String productStockInBase(String unit);
  String productStockTotal(String text);
  String productCurrentStock();
  String productAdjustStock();
  String productSave();
  String productCreate();
  String productCancel();
  String productSaving();
  String productErrNameRequired();
  String productErrSkuRequired();
  String productErrPrice();
  String productErrUnit();
  String productErrTax();
  String productErrFactor();
  String productErrDuplicateUnit();
  String productErrDuplicateBarcode(String barcode);
  String productErrBarcodeTaken(String barcode);
  String productErrOpening();
  String toastProductSaved(String name);
  String toastProductDeactivated(String name);
  String toastProductReactivated(String name);
  String toastProductNoPermission();
  String confirmDeactivateProduct(String name);
  String adjustStockTitle(String name);
  String adjustStockNew();
  String adjustStockChange(String text);
  String adjustReason();
  String adjustReasonCount();
  String adjustReasonDamage();
  String adjustReasonReceived();
  String adjustReasonOther();
  String adjustNote();
  String adjustErrReason();
  String adjustErrNoChange();
  String adjustErrBlocked(String available);
  String adjustConfirm();
  String toastStockAdjusted();
  String helpNewProduct();
  String newProductShortcutMac();
  String newProductShortcutOther();
  String productHintCancel();
  String productHintSave();
  String productStockEntryHint();
  String productAdjustHint();
}
