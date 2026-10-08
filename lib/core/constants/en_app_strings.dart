import 'app_strings.dart';

class EnAppStrings extends AppStrings {
  const EnAppStrings();

  @override
  String appTitle() => 'Axpert POS';

  @override
  String navPos() => 'POS';

  @override
  String navProducts() => 'Products';

  @override
  String navCustomers() => 'Customers';

  @override
  String navSales() => 'Sales';

  @override
  String navReturns() => 'Returns';

  @override
  String navReports() => 'Reports';

  @override
  String navMore() => 'More';

  @override
  String titleSettings() => 'Settings';

  @override
  String workspaceEyebrow() => 'MAISON GALAXY / RETAIL WORKSPACE';

  @override
  String brandMark() => 'A';

  @override
  String brandName() => 'Axpert POS';

  @override
  String storeNameOzone() => 'MAISON GALAXY - OZONE';

  @override
  String storeNameCentral() => 'MAISON GALAXY - CENTRAL';

  @override
  String storeNameMarina() => 'MAISON GALAXY - MARINA';

  @override
  String storeSelectLabel() => 'Store';

  @override
  String searchHint() => 'Scan barcode or search product...';

  @override
  String searchShortcutMac() => '⌘K';

  @override
  String searchShortcutOther() => 'Ctrl+K';

  @override
  String scanTooltip() => 'Scan simulator';

  @override
  String online() => 'Online';

  @override
  String offline() => 'Offline';

  @override
  String notificationsTooltip() => 'Notifications';

  @override
  String notificationsTitle() => 'Notifications';

  @override
  String notificationLowStock() => '🟠 Paper Boat stock is running low';

  @override
  String notificationSynced() => '🟢 All bills successfully synced';

  @override
  String notificationHeld({required int count}) =>
      '🔵 $count held bills waiting';

  @override
  String moreOptionsTooltip() => 'More options';

  @override
  String userInitial() => 'M';

  @override
  String userName() => 'MGTCASH3';

  @override
  String userRole() => 'Cashier';

  @override
  String menuProfile() => 'Profile';

  @override
  String menuSettings() => 'Settings';

  @override
  String menuShortcuts() => 'Shortcuts';

  @override
  String menuLogout() => 'Logout';

  @override
  String storeSwitched() => 'Store switched';

  @override
  String placeholderDialogBody() => 'This screen arrives in a later step.';

  @override
  String dialogClose() => 'Close';

  @override
  String billSummaryTitle() => 'Bill Summary';

  @override
  String offlineBanner() => 'Offline mode – bills will sync later';

  @override
  String toastDismissTooltip() => 'Dismiss notification';

  @override
  String toastUndo() => 'Undo';

  @override
  String shortcutDemo({required String action}) => '$action (demo)';

  @override
  String shortcutCash() => 'Cash payment';

  @override
  String shortcutCard() => 'Card payment';

  @override
  String shortcutHold() => 'Hold bill';

  @override
  String shortcutRecall() => 'Recall bill';

  @override
  String shortcutDiscount() => 'Apply discount';

  @override
  String darkModeTitle() => 'Dark mode';

  @override
  String darkModeHint() => 'A softer screen for evening shifts';

  @override
  String beepTitle() => 'Scan beep';

  @override
  String beepHint() => 'Play a sound after a successful scan';

  @override
  String toastProductAdded(String name) => '$name added';

  @override
  String toastProductRemoved(String name) => '$name removed';

  @override
  String toastStockAvailable(int stock) => 'Available stock: $stock';

  @override
  String toastStockOnly(int stock) => 'Only $stock available in stock';

  @override
  String catalogCaptionTitle() => 'PRODUCT CATALOG';

  @override
  String catalogCaptionCount(int count) => '$count items';

  @override
  String categoryAllItems() => 'All Items';

  @override
  String categoryFavourites() => 'Favourites';

  @override
  String subcategoryAll() => 'All';

  @override
  String moreCategoriesTooltip() => 'More categories';

  @override
  String searchProductHint() => 'Search product by name or code...';

  @override
  String clearSearchTooltip() => 'Clear search';

  @override
  String gridViewTooltip() => 'Grid view';

  @override
  String listViewTooltip() => 'List view';

  @override
  String favouriteTooltip() => 'Toggle favourite';

  @override
  String addProductTooltip(String name) => 'Add $name';

  @override
  String removeOneTooltip(String name) => 'Remove one $name';

  @override
  String qtyBadge(String qty) => 'x$qty';

  @override
  String placeholderJuiceTag() => '100% JUICE';

  @override
  String placeholderCareTag() => 'DAILY CARE';

  @override
  String noResultsTitle() => 'No products found';

  @override
  String noResultsHint() => 'Try another name or category.';

  @override
  String resetFilters() => 'Reset filters';

  @override
  String dialogCloseTooltip() => 'Close dialog';

  @override
  String confirmTitle() => 'Confirm action';

  @override
  String confirmCancel() => 'Cancel';

  @override
  String confirmAccept() => 'Confirm';

  @override
  String confirmClearCart() => 'Clear all items and start a new sale?';

  @override
  String cartTableNumber() => '#';

  @override
  String cartTableItem() => 'Item';

  @override
  String cartTableQty() => 'Qty';

  @override
  String cartTablePrice() => 'Price';

  @override
  String cartTableDiscount() => 'Disc %';

  @override
  String cartTableTotal() => 'Total';

  @override
  String decreaseQtyTooltip() => 'Decrease quantity';

  @override
  String increaseQtyTooltip() => 'Increase quantity';

  @override
  String qtyInputLabel(String name) => '$name quantity';

  @override
  String priceInputLabel(String name) => '$name price';

  @override
  String discountInputLabel(String name) => '$name discount percent';

  @override
  String removeItemTooltip() => 'Remove item';

  @override
  String gstLabel(String percent) => 'GST $percent%';

  @override
  String actionClearCart() => 'Clear Cart';

  @override
  String actionHold() => 'Hold';

  @override
  String actionRecall() => 'Recall';

  @override
  String actionPriceCheck() => 'Price Check';

  @override
  String statTotalItems() => 'Total Items';

  @override
  String statTotalQty() => 'Total Qty';

  @override
  String statTotalValue() => 'Total Value';

  @override
  String lineNumber(int number) => '$number';

  @override
  String summarySubtotal() => 'Subtotal';

  @override
  String summaryDiscount() => 'Discount';

  @override
  String summaryRewardPoints() => 'Reward Points';

  @override
  String summaryTaxAmount() => 'Tax Amount';

  @override
  String summaryInvoiceTotal() => 'Invoice Total';

  @override
  String forexFc() => 'FC';

  @override
  String forexRateLabel() => 'Exchange rate';

  @override
  String forexCurrencySemantic() => 'Conversion currency';

  @override
  String forexRateSemantic() => 'Exchange rate';

  @override
  String forexCurrencyLabel(String code) => code == 'USD' ? r'$' : code;

  @override
  String memberNumberLabel() => 'Member Ship No.';

  @override
  String memberNumberHint() => 'Enter membership no...';

  @override
  String memberFindTooltip() => 'Find member';

  @override
  String memberInfoLabel() => 'Membership Info.';

  @override
  String memberPointsAvailable() => 'Available Points';

  @override
  String memberPointsRedeem() => 'Redeem Points';

  @override
  String memberCompactTitle() => 'Member';

  @override
  String memberAdd() => 'Add membership';

  @override
  String payCash() => 'Cash';

  @override
  String paySaveCredit() => 'Save Credit';

  @override
  String payCard() => 'Card';

  @override
  String amountDue() => 'Amount Due';

  @override
  String amountTendered() => 'Amount Tendered';

  @override
  String amountTenderedHint() => '0.00';

  @override
  String quickAmountExact() => 'Exact';

  @override
  String changeDue() => 'Change Due';

  @override
  String completePayment() => 'Complete Payment';

  @override
  String saveOnCredit() => 'Save on Credit';

  @override
  String terminalAddItems() => 'Add items to begin';

  @override
  String terminalWaiting() => 'Waiting for card...';

  @override
  String terminalApproved() => 'Approved';

  @override
  String terminalDeclined() => 'Card declined';

  @override
  String simulateDecline() => 'Simulate Decline';

  @override
  String terminalRetry() => 'Retry';

  @override
  String actionDiscount() => 'Discount';

  @override
  String actionClearHold() => 'Clear Hold';

  @override
  String actionReprint() => 'Reprint';

  @override
  String actionClear() => 'Clear';

  @override
  String actionClose() => 'Close';

  @override
  String actionTitleWithKey({required String label, required String key}) =>
      '$label ($key)';

  @override
  String saleCash() => 'Cash Sale';

  @override
  String saleCredit() => 'Credit Sale';

  @override
  String customerLabel() => 'Customer';

  @override
  String customerFindTooltip() => 'Find customer';

  @override
  String customerSearchTooltip() => 'Search customers';

  @override
  String addCustomerButton() => 'Add Customer';

  @override
  String addCustomerTooltip() => 'Add customer';

  @override
  String creditValidation() => 'Select a customer to save a credit sale.';

  @override
  String orderNote(String note) => 'Note: $note';

  @override
  String orderOptionsTooltip() => 'Order options';

  @override
  String orderRename() => 'Rename counter';

  @override
  String orderAddNote() => 'Add note';

  @override
  String orderPrintDraft() => 'Print draft';

  @override
  String toastWelcome(String name) => 'Welcome, $name';

  @override
  String toastMemberNotFound() =>
      'Member not found. Try MG1001, MG1002 or MG1003';

  @override
  String toastCreditNeedsCustomer() => 'Select a customer for a credit sale';

  @override
  String toastStockChanged() => 'Stock changed. Please adjust your quantities.';

  @override
  String toastPaymentCompleted() => 'Payment completed';

  @override
  String toastSavedOnCredit() => 'Saved on credit';

  @override
  String confirmSaveCredit({required String total, required String customer}) =>
      'Save $total on credit for $customer?';

  @override
  String confirmDeleteHeld({required int count}) =>
      'Delete all $count held bills?';

  @override
  String toastHeldCleared() => 'Held bills cleared';

  @override
  String countBadge(int count) => '$count';

  @override
  String toastAddItemsBeforeHold() => 'Add items before holding a bill';

  @override
  String toastBillHeld() => 'Bill held. Ready for a new sale.';

  @override
  String toastBillRecalled(String ref) => 'Bill $ref recalled';

  @override
  String heldBillsTitle() => 'Held bills';

  @override
  String heldBillsSubtitle() => 'Pick up right where you left off.';

  @override
  String heldBillRowTitle(String ref, int items) => '$ref · $items items';

  @override
  String heldBillsEmpty() => 'No held bills yet.';

  @override
  String recallConflictTitle() => 'You have an active cart';

  @override
  String recallConflictBody(String ref) =>
      'Hold your current cart, or replace it with $ref?';

  @override
  String recallReplaceCurrent() => 'Replace current';

  @override
  String recallHoldAndRecall() => 'Hold & recall';

  @override
  String discountDrawerTitle() => 'Bill discount';

  @override
  String discountDrawerSubtitle() => 'Apply a discount to this entire bill.';

  @override
  String discountTabPercent() => 'Percentage %';

  @override
  String discountTabFlat() => 'Flat amount ₹';

  @override
  String discountValueLabel() => 'Discount';

  @override
  String discountReasonLabel() => 'Reason';

  @override
  String discountReasonHint() => 'e.g. Seasonal offer';

  @override
  String discountRemove() => 'Remove';

  @override
  String discountApply() => 'Apply discount';

  @override
  String toastProductNotFoundForBarcode(String barcode) =>
      'Product not found for barcode $barcode';

  @override
  String toastProductNotFound() => 'Product not found';

  @override
  String toastCustomerAdded() => 'Customer added';

  @override
  String toastCustomerInvalid() => 'Enter a name, valid phone and email';

  @override
  String scanDialogTitle() => 'Scan simulator';

  @override
  String scanDialogBody() =>
      'Enter a product barcode to simulate your scanner.';

  @override
  String scanInputHint() => '8901234567890';

  @override
  String scanRandom() => 'Scan random product';

  @override
  String scanSimulate() => 'Simulate scan';

  @override
  String scanTryHint() =>
      'Try 8901234567890 for Coca Cola or 8901234567895 for Lays.';

  @override
  String priceCheckBody() =>
      'Scan a barcode or enter a product code. No items will be added.';

  @override
  String priceCheckHint() => 'Barcode or product code';

  @override
  String priceCheckNoMatch() => 'No matching product. Try BDV001.';

  @override
  String priceCheckDetails(String code, int stock, String gst) =>
      '$code · $stock in stock · GST $gst%';

  @override
  String customerPickerTitle() => 'Find a customer';

  @override
  String customerPickerHint() => 'Search name, phone or membership...';

  @override
  String customerRowDetail(String phone, String member, int points) =>
      '$phone $member ${member.isEmpty ? '' : '· $points points'}';

  @override
  String customerAddButton() => 'Add Customer';

  @override
  String addCustomerTitle() => 'Add Customer';

  @override
  String addCustomerBody() => 'A little personal service goes a long way.';

  @override
  String addCustomerName() => 'Name *';

  @override
  String addCustomerPhone() => 'Phone *';

  @override
  String addCustomerEmail() => 'Email';

  @override
  String addCustomerSave() => 'Save customer';

  @override
  String searchResultsLabel() => 'Search results';
}
