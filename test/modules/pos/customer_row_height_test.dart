// The customer row: the dropdown field, its search segment and the Add
// Customer button share one height (`fieldHeight`) at every size (DEC-140).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/widgets/customer_row.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';
import 'package:pos_application/shared/widgets/app_pressable.dart';
import 'package:pos_application/shared/widgets/css_gradient.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

const _sizes = <Size>[
  Size(950, 600),
  Size(950, 900),
  Size(1280, 600),
  Size(1280, 720),
  Size(1868, 900),
  Size(1868, 1035),
];

void main() {
  useTestApp();

  for (final size in _sizes) {
    testWidgets('field, search segment and Add Customer are equally tall at '
        '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        useLogicalViewport(tester, size);
        final binding = await bootInWidgetTest(tester);
        await tester.pumpWidget(testApp(binding));
        await tester.pumpAndSettle();
        Get.find<CartActionsController>().add(
          Get.find<ProductsController>().products.first,
        );
        await tester.pumpAndSettle();
        Get.find<ToastController>().toasts.clear();
        await tester.pumpAndSettle();

        final row = find.byType(CustomerRow);
        expect(row, findsOneWidget);
        final field = tester.getSize(
          find.descendant(of: row, matching: find.byType(CssGradientBox)),
        );
        final search = tester.getSize(
          find.descendant(
            of: row,
            matching: find.byWidgetPredicate(
              (w) => w is Tooltip && w.message == 'Find customer',
            ),
          ),
        );
        final add = tester.getSize(
          find.ancestor(
            of: find.descendant(of: row, matching: find.text('Add Customer')),
            matching: find.byType(AppPressable),
          ),
        );
        expect(add.height, greaterThan(0));
        // The search segment sits inside the field's 1 px borders.
        expect(field.height, add.height);
        expect(search.height, add.height - 2);
      } finally {
        await tester.pump(const Duration(seconds: 6));
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
