import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_pages.dart';
import 'package:pos_application/core/routes/app_routes.dart';

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
    const titles = <String, String>{
      AppRoutes.products: 'Products',
      AppRoutes.customers: 'Customers',
      AppRoutes.sales: 'Sales',
      AppRoutes.returns: 'Returns',
      AppRoutes.reports: 'Reports',
      AppRoutes.more: 'Settings',
      AppRoutes.pos: 'POS',
    };
    for (final entry in titles.entries) {
      Get.offAllNamed<void>(entry.key);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
    }
    Get.offAllNamed<void>('/does-not-exist');
    await tester.pumpAndSettle();
    expect(find.text('POS'), findsOneWidget);
  });
}
