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
}
