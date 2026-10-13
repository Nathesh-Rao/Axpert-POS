// KG-218 (open): the India Bill Summary has ONE compact CGST/SGST row under the
// tax row. It does not yet fit 1280 x 720 without scrolling (the layout
// already scrolls there with the tax row alone); see the known gap.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/widgets/summary/bill_summary_body.dart';
import 'package:pos_application/modules/pos/widgets/summary/quick_actions_grid.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

/// Measured at 1280 x 720 with a tax row and no split (VAT store).
const double kBaselineOverflow = 12;

void main() {
  useTestApp();

  testWidgets('India summary at 1280 x 720: the split adds one compact row', (
    tester,
  ) async {
    const size = Size(1280, 720);
    useLogicalViewport(tester, size);
    final binding = await bootInWidgetTest(tester);
    await tester.pumpWidget(testApp(binding));
    await tester.pumpAndSettle();
    Get.find<CartActionsController>().add(
      Get.find<ProductsController>().byId(5)!,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('CGST'), findsOneWidget);
    expect(find.text('SGST'), findsOneWidget);
    // CGST and SGST sit on one row: the same vertical position.
    expect(
      tester.getCenter(find.text('CGST')).dy,
      closeTo(tester.getCenter(find.text('SGST')).dy, 0.5),
    );
    expect(
      tester.getCenter(find.text('CGST')).dx,
      lessThan(tester.getCenter(find.text('SGST')).dx),
    );

    double overflow() => tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(BillSummaryBody),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .maxScrollExtent;
    final india = overflow();
    // KG-218 stays OPEN: with only the single tax row (a VAT store) this
    // window already scrolls by the amount below, so the split row can only
    // add its own height. This guards that it adds exactly one compact row
    // (22 px at this density) and not two full rows (56 px).
    expect(india, lessThanOrEqualTo(kBaselineOverflow + 22));
    expect(
      tester.getRect(find.byType(QuickActionsGrid)).bottom,
      lessThanOrEqualTo(size.height + india),
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });
}
