// The desktop cart-first layout (DEC-138): collapsed and expanded Products
// panel, compact rows and the slim footer, light and dark, no overflow.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/products_panel_controller.dart';
import 'package:pos_application/modules/pos/widgets/cart_compact_row.dart';
import 'package:pos_application/modules/pos/widgets/cart_compact_table.dart';
import 'package:pos_application/modules/pos/widgets/cart_footer.dart';
import 'package:pos_application/modules/pos/widgets/catalog_panel.dart';
import 'package:pos_application/modules/pos/widgets/products_tab.dart';
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
  bool open = false,
}) async {
  useLogicalViewport(tester, size);
  final binding = await bootInWidgetTest(tester);
  if (dark) {
    await tester.runAsync(() => Get.find<SettingsController>().setDark(true));
  }
  if (open) {
    await tester.runAsync(
      () => Get.find<ProductsPanelController>().setOpen(true),
    );
  }
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  final products = Get.find<ProductsController>();
  for (var i = 0; i < lines; i++) {
    Get.find<CartActionsController>().add(products.products[i]);
  }
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
      testWidgets(
        'desktop cart ${size.width.toInt()}x${size.height.toInt()} '
        '${dark ? 'dark' : 'light'}: 14 lines, collapsed panel, compact rows',
        (tester) async {
          debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
          try {
            await _boot(tester, size, dark: dark, lines: 14);
            expect(tester.takeException(), isNull);
            expect(find.byType(ProductsTab), findsOneWidget);
            expect(find.byType(CatalogPanel), findsNothing);
            final rows = find.byType(CartCompactRow);
            expect(rows, findsWidgets);
            expect(tester.getSize(rows.first).height, 48);
            final visible = _visibleRows(tester);
            // ignore: avoid_print
            print(
              'ROWS ${size.width.toInt()}x${size.height.toInt()}: $visible',
            );
            expect(visible, greaterThanOrEqualTo(size.height >= 1000 ? 12 : 8));
            expect(
              tester.getSize(find.byType(CartFooter)).height,
              lessThanOrEqualTo(44),
            );
            await tester.pump(const Duration(seconds: 6));
            await tester.pumpAndSettle();
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        },
      );
    }
  }
}
