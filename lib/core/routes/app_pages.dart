import 'package:get/get.dart';

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
        page: () => PagePlaceholder(page: page),
        transition: Transition.noTransition,
      );
}
