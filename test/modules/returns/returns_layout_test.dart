// Returns across window sizes (smaller sweep): nothing outside the panel, the
// 550 column, quantity boxes aligned and clear of long names, paddings. VM.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/theme/tokens/app_management_sizes.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/modules/products/models/product.dart';
import 'package:pos_application/modules/returns/controllers/returns_controller.dart';
import 'package:pos_application/modules/returns/widgets/return_line.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';
import 'package:pos_application/shared/widgets/app_input_box.dart';
import 'package:pos_application/shared/widgets/app_panel.dart';
import 'package:pos_application/shared/widgets/management_page.dart';

import '../../support/layout_matrix.dart';
import '../../support/sale_fixtures.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

Rect _r(WidgetTester t, Finder f) => t.getRect(f);

void main() {
  useTestApp();

  for (final w in smallWidths) {
    for (final h in smallHeights) {
      final size = Size(w, h);
      testWidgets('Returns at ${w.toInt()} x ${h.toInt()}', (tester) async {
        useLogicalViewport(tester, size);
        final binding = await bootInWidgetTest(tester);
        await tester.pumpWidget(testApp(binding));
        await tester.pumpAndSettle();
        final pad = AppMetrics(size).managementPad;
        final products = Get.find<ProductsController>();
        const long =
            'Extra Large Family Pack Roasted Salted Cashew Nuts With Himalayan '
            'Pink Salt and Black Pepper 1 kg Resealable Pouch Limited Edition';
        final longProduct = products.byId(0)!;
        Get.find<SalesController>().sales.add(
          testSale(
            number: 'AX000007',
            at: DateTime(2026, 10, 8),
            customer: 'Venkata Subramanian Krishnamurthy Iyer',
            totalMinor: 99999999,
            valueMinor: 99999999,
            cart: Cart(
              lines: <CartLine>[
                CartLine(
                  product: Product(
                    id: longProduct.id,
                    name: long,
                    code: longProduct.code,
                    barcode: longProduct.barcode,
                    price: longProduct.price,
                    category: longProduct.category,
                    sub: longProduct.sub,
                    stock: longProduct.stock,
                    gst: longProduct.gst,
                    image: longProduct.image,
                    favourite: false,
                  ),
                  qty: const Qty(2500),
                  price: const Money(100, CurrencyRegistry.inr),
                  discount: Bp.zero,
                ),
                CartLine(
                  product: products.byId(1)!,
                  qty: const Qty(1000),
                  price: const Money(100, CurrencyRegistry.inr),
                  discount: Bp.zero,
                ),
              ],
            ),
          ),
        );
        Get.offAllNamed<void>(AppRoutes.returns);
        await tester.pumpAndSettle();
        final page = Get.find<ReturnsController>();

        // ---- empty ----
        expect(tester.takeException(), isNull, reason: 'empty $size');
        final panel = _r(
          tester,
          find
              .descendant(
                of: find.byType(ManagementPage),
                matching: find.byType(AppPanel),
              )
              .first,
        );
        final title = _r(tester, find.text('Find a bill to return items'));
        final box = _r(tester, find.byType(ManagementSearch));
        final hint = _r(
          tester,
          find.text('Enter a completed bill number to begin.'),
        );
        expect(title.left - panel.left, closeTo(pad, 0.6), reason: '$size');
        expect(
          box.top - title.bottom,
          greaterThanOrEqualTo(
            AppManagementSizes.returnsTitleMarginBottom - 0.5,
          ),
          reason: 'title gap $size',
        );
        expect(
          box.width,
          lessThanOrEqualTo(AppManagementSizes.returnsMaxWidth + 0.5),
        );
        expect(
          hint.top - box.bottom,
          greaterThanOrEqualTo(
            AppManagementSizes.returnsParagraphMarginY - 0.5,
          ),
          reason: 'hint gap $size',
        );

        // ---- no match ----
        page.onBillChanged('nope');
        await tester.pumpAndSettle();
        expect(find.text('No matching bill found.'), findsOneWidget);

        // ---- matched ----
        page.onBillChanged('AX000007');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'matched $size');
        final lines = <Rect>[
          for (final e in tester.elementList(find.byType(ReturnLine)))
            tester.getRect(find.byWidget(e.widget)),
        ];
        expect(lines, hasLength(2));
        final boxes = <Rect>[
          for (final id in <int>[0, 1])
            _r(
              tester,
              find.ancestor(
                of: find.byWidgetPredicate(
                  (w) => w is TextField && w.controller == page.fieldFor(id),
                ),
                matching: find.byType(AppInputBox),
              ),
            ),
        ];
        for (var i = 0; i < 2; i++) {
          expect(
            lines[i].width,
            lessThanOrEqualTo(AppManagementSizes.returnsMaxWidth + 0.5),
            reason: 'line width $size',
          );
          expect(boxes[i].right, closeTo(lines[i].right, 0.6), reason: '$size');
          expect(
            boxes[i].width,
            closeTo(AppManagementSizes.returnInputWidth, 0.6),
            reason: '$size',
          );
          expect(
            boxes[i].top - lines[i].top,
            greaterThanOrEqualTo(AppManagementSizes.returnLinePadY - 0.5),
            reason: 'line pad $size',
          );
        }
        expect(boxes[0].left, closeTo(boxes[1].left, 0.6), reason: '$size');
        // The long name wraps left of its quantity box.
        final name = _r(tester, find.text(long));
        expect(
          name.right,
          lessThanOrEqualTo(boxes[0].left + 0.5),
          reason: '$size',
        );
        // The button keeps its distance from the last line.
        final button = _r(tester, find.text('Refund & restock'));
        expect(
          button.top - lines.last.bottom,
          greaterThanOrEqualTo(AppManagementSizes.returnsButtonMarginTop - 0.5),
          reason: 'button gap $size',
        );
        // The huge total stays on one line inside the column.
        final summary = _r(
          tester,
          find.textContaining('Venkata Subramanian Krishnamurthy Iyer · '),
        );
        expect(summary.right, lessThanOrEqualTo(panel.right - pad + 0.5));
        await tester.pump(const Duration(milliseconds: 100));
      });
    }
  }
}
