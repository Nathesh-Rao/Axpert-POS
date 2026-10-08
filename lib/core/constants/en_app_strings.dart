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
}
