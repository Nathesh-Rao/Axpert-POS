import 'package:flutter/widgets.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/tokens/app_icons.dart';

/// One sidebar entry: route, icon and label.
class NavDestination {
  const NavDestination(this.page, this.icon, this._label);

  final AppPage page;
  final IconData icon;
  final String Function(AppStrings) _label;

  String label(AppStrings strings) => _label(strings);

  static final List<NavDestination> all = <NavDestination>[
    NavDestination(AppPage.pos, AppIcons.shoppingCart, (s) => s.navPos()),
    NavDestination(
      AppPage.products,
      AppIcons.shoppingBag,
      (s) => s.navProducts(),
    ),
    NavDestination(AppPage.customers, AppIcons.users, (s) => s.navCustomers()),
    NavDestination(AppPage.sales, AppIcons.fileText, (s) => s.navSales()),
    NavDestination(AppPage.returns, AppIcons.undo2, (s) => s.navReturns()),
    NavDestination(
      AppPage.reports,
      AppIcons.chartNoAxesColumnIncreasing,
      (s) => s.navReports(),
    ),
    NavDestination(AppPage.more, AppIcons.ellipsis, (s) => s.navMore()),
  ];
}
