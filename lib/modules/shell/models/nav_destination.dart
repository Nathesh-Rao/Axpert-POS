import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/routes/app_routes.dart';

/// One sidebar entry: route, icon and label.
class NavDestination {
  const NavDestination(this.page, this.icon, this._label);

  final AppPage page;
  final IconData icon;
  final String Function(AppStrings) _label;

  String label(AppStrings strings) => _label(strings);

  static final List<NavDestination> all = <NavDestination>[
    NavDestination(AppPage.pos, LucideIcons.shoppingCart, (s) => s.navPos()),
    NavDestination(
      AppPage.products,
      LucideIcons.shoppingBag,
      (s) => s.navProducts(),
    ),
    NavDestination(
      AppPage.customers,
      LucideIcons.users,
      (s) => s.navCustomers(),
    ),
    NavDestination(AppPage.sales, LucideIcons.fileText, (s) => s.navSales()),
    NavDestination(AppPage.returns, LucideIcons.undo2, (s) => s.navReturns()),
    NavDestination(
      AppPage.reports,
      LucideIcons.chartNoAxesColumnIncreasing,
      (s) => s.navReports(),
    ),
    NavDestination(AppPage.more, LucideIcons.ellipsis, (s) => s.navMore()),
  ];
}
