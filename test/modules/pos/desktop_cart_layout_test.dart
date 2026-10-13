// The desktop POS work area (DEC-139): the cart view (compact rows, slim
// footer) and the catalog view over the whole width, light and dark, at the
// three reference sizes, with no overflow while the view changes.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/pos_work_view_controller.dart';
import 'package:pos_application/modules/pos/widgets/cart_compact_row.dart';
import 'package:pos_application/modules/pos/widgets/cart_compact_table.dart';
import 'package:pos_application/modules/pos/widgets/cart_footer.dart';
import 'package:pos_application/modules/pos/widgets/catalog_panel.dart';
import 'package:pos_application/modules/pos/widgets/desktop_cart_column.dart';
import 'package:pos_application/modules/pos/widgets/work_tab.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

const _sizes = <Size>[Size(950, 733), Size(1280, 720), Size(1868, 1035)];

Future<void> _boot(
  WidgetTester tester,
  Size size, {
  required bool dark,
  required int lines,
}) async {
  useLogicalViewport(tester, size);
  final binding = await bootInWidgetTest(tester);
  if (dark) {
    await tester.runAsync(() => Get.find<SettingsController>().setDark(true));
  }
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  final products = Get.find<ProductsController>();
  for (var i = 0; i < lines; i++) {
    Get.find<CartActionsController>().add(products.products[i]);
  }
  // Adding through the actions shows the cart (the cart became active).
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  Get.find<ToastController>().toasts.clear();
  await tester.pumpAndSettle();
}

/// Rows of the cart table that lie fully inside its list viewport.
int _visibleRows(WidgetTester tester) {
  final table = tester.getRect(find.byType(CartCompactTable));
  var count = 0;
  for (final e in find.byType(CartCompactRow).evaluate()) {
    final r = tester.getRect(find.byWidget(e.widget));
    if (r.top >= table.top && r.bottom <= table.bottom + 0.01) count++;
  }
  return count;
}

void main() {
  useTestApp();

  for (final size in _sizes) {
    for (final dark in <bool>[false, true]) {
      final name =
          '${size.width.toInt()}x${size.height.toInt()} '
          '${dark ? 'dark' : 'light'}';
      testWidgets('cart view and catalog view at $name', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          await _boot(tester, size, dark: dark, lines: 14);
          expect(tester.takeException(), isNull);
          final work = Get.find<PosWorkViewController>();

          // CART view: the cart over the whole work area, 48 px rows.
          expect(work.view, PosWorkView.cart);
          final tab = tester.getRect(find.byType(WorkTab));
          final cart = tester.getRect(find.byType(DesktopCartColumn));
          expect(cart.left, greaterThan(tab.right));
          expect(cart.right, greaterThan(size.width * 0.6));
          expect(find.byType(CatalogPanel).hitTestable(), findsNothing);
          final rows = find.byType(CartCompactRow);
          expect(tester.getSize(rows.first).height, 48);
          final visible = _visibleRows(tester);
          // ignore: avoid_print
          print('ROWS $name: $visible');
          expect(visible, greaterThanOrEqualTo(size.height >= 1000 ? 12 : 8));
          expect(
            tester.getSize(find.byType(CartFooter)).height,
            lessThanOrEqualTo(44),
          );
          expect(
            find.descendant(
              of: find.byType(WorkTab),
              matching: find.text('Products'),
            ),
            findsOneWidget,
          );

          // CATALOG view: the catalog over the same width, the cart gone.
          work.toggle();
          await tester.pumpAndSettle();
          expect(work.view, PosWorkView.catalog);
          expect(tester.takeException(), isNull);
          final catalog = tester.getRect(find.byType(CatalogPanel));
          expect(catalog.left, closeTo(cart.left, 0.5));
          expect(catalog.width, closeTo(cart.width, 0.5));
          expect(find.byType(DesktopCartColumn).hitTestable(), findsNothing);
          expect(
            find.descendant(
              of: find.byType(WorkTab),
              matching: find.text('Cart (14)'),
            ),
            findsOneWidget,
          );

          // Back, with the animation settled at every step.
          work.toggle();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(
            tester.getRect(find.byType(DesktopCartColumn)).width,
            closeTo(cart.width, 0.5),
          );
          await tester.pump(const Duration(seconds: 6));
          await tester.pumpAndSettle();
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }

  testWidgets('mid-transition the two views share the work width', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _boot(tester, const Size(1280, 720), dark: false, lines: 3);
      final work = Get.find<PosWorkViewController>();
      double slot(Type child) => tester
          .getSize(
            find
                .ancestor(
                  of: find.byType(child),
                  matching: find.byType(ClipRect),
                )
                .first,
          )
          .width;
      final full = slot(DesktopCartColumn);
      work.toggle();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      final cartNow = slot(DesktopCartColumn);
      final catalogNow = slot(CatalogPanel);
      expect(cartNow, lessThan(full));
      expect(cartNow, greaterThan(0));
      expect(catalogNow, greaterThan(0));
      expect(cartNow + catalogNow, closeTo(full, 0.5), reason: 'they share it');
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
