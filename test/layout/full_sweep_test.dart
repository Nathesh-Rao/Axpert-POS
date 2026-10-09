// The FULL layout sweep (S7, run once): every screen and dialog at every size
// of the matrix (widths 900-1900 x heights 600-1000). Per screen and size: no
// framework exception (a RenderFlex overflow is one), the page panel and every
// dialog card inside the window. One test per width so a failure names it.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/hold_recall_controller.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/modules/returns/controllers/returns_controller.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';
import 'package:pos_application/modules/sales/models/sale.dart';
import 'package:pos_application/modules/shift/controllers/shift_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';
import 'package:pos_application/shared/widgets/app_drawer.dart';
import 'package:pos_application/shared/widgets/app_modal.dart';
import 'package:pos_application/shared/widgets/app_panel.dart';

import '../support/layout_matrix.dart';
import '../support/sale_fixtures.dart';
import '../support/test_app.dart';
import '../support/viewport.dart';

const List<String> _dialogs = <String>[
  'settings',
  'profile',
  'close',
  'shortcuts',
  'scan',
  'priceCheck',
  'customers',
  'addCustomer',
  'recall',
  'discount',
  'counter',
  'note',
  'reprint',
  'receipt',
  'confirm',
];

Sale _sale(ProductsController products) => testSale(
  number: 'AX000001',
  at: DateTime(2026, 10, 8, 11, 30),
  customer: 'Ananya Sharma',
  totalMinor: 12980,
  valueMinor: 11000,
  cart: Cart(
    lines: <CartLine>[
      CartLine(
        product: products.byId(0)!,
        qty: const Qty(2000),
        price: const Money(4000, CurrencyRegistry.inr),
        discount: Bp.zero,
      ),
      CartLine(
        product: products.byId(1)!,
        qty: const Qty(1500),
        price: const Money(2000, CurrencyRegistry.inr),
        discount: const Bp(1000),
      ),
    ],
  ),
);

void _inside(Rect r, Size w, String why) {
  expect(r.left, greaterThanOrEqualTo(-0.5), reason: 'left $why $r');
  expect(r.top, greaterThanOrEqualTo(-0.5), reason: 'top $why $r');
  expect(r.right, lessThanOrEqualTo(w.width + 0.5), reason: 'right $why $r');
  expect(r.bottom, lessThanOrEqualTo(w.height + 0.5), reason: 'bottom $why $r');
}

void main() {
  useTestApp();

  for (final w in matrixWidths) {
    testWidgets('full sweep at width ${w.toInt()}', (tester) async {
      useLogicalViewport(tester, Size(w, matrixHeights.first));
      final binding = await bootInWidgetTest(tester);
      await tester.pumpWidget(testApp(binding));
      await tester.pumpAndSettle();

      // Data: a held bill, cart lines, a sale with lines.
      final products = Get.find<ProductsController>();
      final actions = Get.find<CartActionsController>();
      actions.add(products.byId(2)!);
      Get.find<HoldRecallController>().hold();
      for (final id in <int>[0, 1, 5, 7]) {
        actions.add(products.byId(id)!);
      }
      final sale = _sale(products);
      Get.find<SalesController>().sales.add(sale);
      await tester.pump();
      final overlay = Get.find<OverlayController>();

      Future<void> settle() async {
        await tester.pumpAndSettle();
        Get.find<ToastController>().toasts.clear();
      }

      for (final h in matrixHeights) {
        final size = Size(w, h);
        useLogicalViewport(tester, size);
        await tester.pumpAndSettle();

        // ---- routes ----
        for (final route in <String>[
          AppRoutes.pos,
          AppRoutes.products,
          AppRoutes.customers,
          AppRoutes.sales,
          AppRoutes.returns,
          AppRoutes.reports,
          AppRoutes.more,
        ]) {
          // The sidebar never re-opens the current page, so neither does this.
          if (Get.currentRoute != route) Get.offAllNamed<void>(route);
          await settle();
          if (route == AppRoutes.returns) {
            final page = Get.find<ReturnsController>();
            page.billNumber.text = 'AX000001';
            page.onBillChanged('AX000001');
            await settle();
          }
          expect(tester.takeException(), isNull, reason: '$route $size');
          for (final e in tester.elementList(find.byType(AppPanel))) {
            _inside(
              tester.getRect(find.byWidget(e.widget)),
              size,
              '$route $size',
            );
          }
        }

        // ---- dialogs (over POS) ----
        if (Get.currentRoute != AppRoutes.pos) {
          Get.offAllNamed<void>(AppRoutes.pos);
        }
        await settle();
        for (final id in _dialogs) {
          if (id == 'confirm') {
            overlay.openConfirm(
              'Refund ₹47.20 and restock selected items?',
              () {},
            );
          } else {
            overlay.open(id, payload: id == 'receipt' ? sale : null);
          }
          await settle();
          expect(tester.takeException(), isNull, reason: '$id $size');
          final card = find.byWidgetPredicate(
            (w) => w is AppModal || w is AppDrawer,
          );
          expect(card, findsAtLeastNWidgets(1), reason: '$id $size');
          for (final e in tester.elementList(card)) {
            _inside(tester.getRect(find.byWidget(e.widget)), size, '$id $size');
          }
          overlay.close();
          await settle();
          await tester.pump(const Duration(milliseconds: 100));
        }

        // ---- counter closed ----
        Get.find<ShiftController>().closeCounter();
        await settle();
        expect(tester.takeException(), isNull, reason: 'signed out $size');
        _inside(
          tester.getRect(find.text('Counter closed')),
          size,
          'closed $size',
        );
        _inside(
          tester.getRect(find.text('Start new shift')),
          size,
          'start $size',
        );
        Get.find<ShiftController>().startNewShift();
        await settle();
      }
      await tester.pump(const Duration(seconds: 6));
    });
  }
}
