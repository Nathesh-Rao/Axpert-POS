import 'package:get/get.dart';

import '../../modules/customers/bindings/customers_binding.dart';
import '../../modules/customers/views/customers_view.dart';
import '../../modules/pos/bindings/pos_binding.dart';
import '../../modules/pos/views/pos_view.dart';
import '../../modules/products/bindings/products_binding.dart';
import '../../modules/products/views/products_view.dart';
import '../../modules/shell/views/page_placeholder.dart';
import 'app_routes.dart';

/// Seven named routes, no transition. Unknown paths fall through to POS.
abstract final class AppPages {
  static const String initial = AppRoutes.pos;

  static final GetPage<dynamic> unknown = _page(AppPage.pos, name: '/404');

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    for (final page in AppPage.values) _page(page),
  ];

  static GetPage<dynamic> _page(AppPage page, {String? name}) =>
      GetPage<dynamic>(
        name: name ?? page.path,
        page: () => switch (page) {
          AppPage.pos => const PosView(),
          AppPage.products => const ProductsView(),
          AppPage.customers => const CustomersView(),
          _ => PagePlaceholder(page: page),
        },
        binding: switch (page) {
          AppPage.pos => PosBinding(),
          AppPage.products => ProductsBinding(),
          AppPage.customers => CustomersBinding(),
          _ => null,
        },
        transition: Transition.noTransition,
      );
}
