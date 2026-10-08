import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_pages.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/modules/customers/views/customers_view.dart';
import 'package:pos_application/modules/pos/views/pos_view.dart';
import 'package:pos_application/modules/products/views/products_view.dart';
import 'package:pos_application/modules/shell/views/page_placeholder.dart';

import '../../support/test_app.dart';

void main() {
  useTestApp();

  test('seven named routes without transition', () {
    expect(AppPages.pages.map((p) => p.name), <String>[
      '/',
      '/products',
      '/customers',
      '/sales',
      '/returns',
      '/reports',
      '/more',
    ]);
    for (final page in AppPages.pages) {
      expect(page.transition, Transition.noTransition);
    }
  });

  test('unknown paths fall through to POS', () {
    expect(AppPage.fromPath('/nope'), AppPage.pos);
    expect(AppPage.fromPath(null), AppPage.pos);
    expect(AppPage.fromPath('/sales'), AppPage.sales);
  });

  testWidgets('every route resolves and unknown shows POS', (tester) async {
    final binding = await bootInWidgetTest(tester);
    await tester.pumpWidget(testApp(binding));
    await tester.pumpAndSettle();
    AppPage shown() {
      if (find.byType(PosView).evaluate().isNotEmpty) return AppPage.pos;
      if (find.byType(ProductsView).evaluate().isNotEmpty) {
        return AppPage.products;
      }
      if (find.byType(CustomersView).evaluate().isNotEmpty) {
        return AppPage.customers;
      }
      return tester.widget<PagePlaceholder>(find.byType(PagePlaceholder)).page;
    }

    for (final page in AppPage.values) {
      Get.offAllNamed<void>(page.path);
      await tester.pumpAndSettle();
      expect(shown(), page, reason: page.path);
    }
    Get.offAllNamed<void>('/does-not-exist');
    await tester.pumpAndSettle();
    expect(shown(), AppPage.pos);
  });
}
