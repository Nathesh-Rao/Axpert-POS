// DEC-112 (user-approved deviation from React): paired buttons have equal
// height, equal top and bottom edges and a shared label baseline. One widget
// (ModalActions) draws every pair: Scan simulator, Confirm dialog, Bill
// discount drawer and the recall question.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/theme/tokens/app_sizes.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/hold_recall_controller.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/widgets/modal_actions.dart';

import '../support/test_app.dart';
import '../support/viewport.dart';

void main() {
  useTestApp();

  Future<void> expectPair(WidgetTester tester, String why) async {
    final actions = find.byType(ModalActions);
    expect(actions, findsOneWidget, reason: why);
    final w = tester.widget<ModalActions>(actions);
    Finder button(String label) => find.ancestor(
      of: find.descendant(of: actions, matching: find.text(label)),
      matching: find.byType(Container),
    );
    final a = button(w.secondaryLabel).first;
    final b = button(w.primaryLabel).first;
    final ra = tester.getRect(a), rb = tester.getRect(b);
    expect(ra.height, rb.height, reason: '$why: equal height');
    expect(ra.top, rb.top, reason: '$why: same top');
    expect(ra.bottom, rb.bottom, reason: '$why: same bottom');
    // the test font is wider than Roboto Condensed, so labels may wrap: both
    // buttons then grow together, never below the standard height
    expect(
      ra.height,
      greaterThanOrEqualTo(AppSizes.controlMinHeight),
      reason: '$why: standard',
    );
    // labels centred in their buttons: same vertical centre = same baseline
    final ta = tester.getRect(
      find.descendant(of: actions, matching: find.text(w.secondaryLabel)),
    );
    final tb = tester.getRect(
      find.descendant(of: actions, matching: find.text(w.primaryLabel)),
    );
    expect(ta.center.dy, tb.center.dy, reason: '$why: label baseline');
  }

  testWidgets('every ModalActions pair is equal height and aligned', (
    tester,
  ) async {
    useLogicalViewport(tester, const Size(1280, 720));
    final binding = await bootInWidgetTest(tester);
    await tester.pumpWidget(testApp(binding));
    await tester.pumpAndSettle();
    final overlay = Get.find<OverlayController>();
    Get.find<CartActionsController>().add(
      Get.find<ProductsController>().byId(5)!,
    );
    await tester.pumpAndSettle();
    Get.find<CartActionsController>().add(
      Get.find<ProductsController>().byId(6)!,
    );
    await tester.pump(const Duration(seconds: 6));
    // one held bill, then an active cart: picking it asks the question
    final flow = Get.find<HoldRecallController>();
    flow.hold();
    Get.find<CartActionsController>().add(
      Get.find<ProductsController>().byId(7)!,
    );
    await tester.pump(const Duration(seconds: 6));
    for (final id in <String>['scan', 'discount', 'recall', 'confirm']) {
      if (id == 'confirm') {
        overlay.openConfirm('Confirm?', () {});
      } else {
        overlay.open(id);
      }
      await tester.pumpAndSettle();
      if (id == 'recall') {
        flow.pick(flow.held.bills.first);
        await tester.pumpAndSettle();
      }
      await expectPair(tester, id);
      overlay.close();
      await tester.pumpAndSettle();
    }
  });
}
