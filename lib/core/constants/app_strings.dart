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
}
