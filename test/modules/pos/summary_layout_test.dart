// The Bill Summary and the cart panel across window sizes (width 1000 to 1900,
// height 600 to 1000): flutter_test fails on any RenderFlex error, and key
// texts are measured (one line, no per-character wrapping, inside the
// window). Runs on VM and Chrome.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';

import '../../support/layout_matrix.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

void main() {
  useTestApp();

  for (final w in matrixWidths) {
    for (final h in matrixHeights) {
      testWidgets('summary and cart panel at ${w.toInt()} x ${h.toInt()}', (
        tester,
      ) async {
        final size = Size(w, h);
        useLogicalViewport(tester, size);
        final binding = await bootInWidgetTest(tester);
        await tester.pumpWidget(testApp(binding));
        await tester.pumpAndSettle();

        // Empty cart: the customer chip header.
        for (final text in <String>['Cash Sale', 'Credit Sale']) {
          expectReadable(tester, find.text(text), size, reason: 'empty $text');
        }
        expect(tester.takeException(), isNull);

        Get.find<CartActionsController>().add(
          Get.find<ProductsController>().byId(5)!,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);

        for (final text in <String>[
          'Subtotal',
          'Invoice Total',
          'Amount Due',
          'Change Due',
          'Complete Payment',
          'Cash Sale',
          'Credit Sale',
          'Add Customer',
          'Customer',
          'Exact',
        ]) {
          expectReadable(tester, find.text(text), size, reason: text);
        }
        // Money values keep their full text on one line.
        for (final value in <String>['₹21.00', '₹20.00']) {
          expect(find.text(value), findsWidgets);
          expectReadable(tester, find.text(value).first, size, minPerChar: 5);
        }
        // From height 820 up the whole checkout section is visible: the
        // Complete button lies inside the window.
        if (h >= 820) {
          final rect = tester.getRect(find.text('Complete Payment'));
          expect(rect.bottom, lessThanOrEqualTo(h), reason: 'complete visible');
        }
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
      });
    }
  }
}
