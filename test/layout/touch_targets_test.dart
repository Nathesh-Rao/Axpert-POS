// Tablet touch-target audit (S7, REPORT ONLY): every tappable control on every
// route and dialog at tablet landscape sizes, its size, and whether it reaches
// 44 px (and 48 px). Prints `TOUCH|size|screen|type|label|w|h` lines that
// docs/responsive_report.md is built from. Nothing here fails on a small
// control (React's sizes are kept, Phase A); it fails only on an exception.
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
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';
import 'package:pos_application/shared/widgets/app_drawer.dart';
import 'package:pos_application/shared/widgets/app_modal.dart';
import 'package:pos_application/shared/widgets/app_pressable.dart';

import '../golden/harness.dart' show loadTestFonts;
import '../support/layout_matrix.dart';
import '../support/sale_fixtures.dart';
import '../support/test_app.dart';
import '../support/viewport.dart';

const List<Size> _sizes = <Size>[
  Size(1024, 768),
  Size(1100, 733),
  Size(1180, 820),
  Size(1194, 834),
  Size(1280, 800),
  Size(900, 600),
  Size(768, 576),
];

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

String _label(Element e) {
  final w = e.widget;
  if (w is AppPressable) {
    if (w.tooltip != null) return w.tooltip!;
    if (w.semanticLabel != null) return w.semanticLabel!;
  }
  String? text;
  IconData? icon;
  void visit(Element c) {
    if (text != null) return;
    final cw = c.widget;
    if (cw is Text && cw.data != null && cw.data!.trim().isNotEmpty) {
      text = cw.data;
      return;
    }
    if (cw is Icon && cw.icon != null) icon ??= cw.icon;
    c.visitChildren(visit);
  }

  e.visitChildren(visit);
  if (text != null) return text!;
  if (icon != null) return 'icon U+${icon!.codePoint.toRadixString(16)}';
  return '-';
}

/// At and above the 900 px floor an exception fails the test; below it the
/// overflow is only reported (`OVERFLOW|screen|first line`).
void _check(WidgetTester tester, Size size, String screen) {
  final error = tester.takeException();
  if (error == null) return;
  if (size.width >= 900) {
    fail('exception at $screen: $error');
  }
  final line = error.toString().split('\n').first;
  // ignore: avoid_print
  print('OVERFLOW|$screen|$line');
}

void main() {
  useTestApp();

  testWidgets('touch target audit (report only)', (tester) async {
    // The real Roboto Condensed, so FittedBox scale-downs match the app (the
    // default test font is much wider).
    await tester.runAsync(loadTestFonts);
    useLogicalViewport(tester, _sizes.first);
    final binding = await bootInWidgetTest(tester);
    await tester.pumpWidget(testApp(binding));
    await tester.pumpAndSettle();
    final products = Get.find<ProductsController>();
    final actions = Get.find<CartActionsController>();
    actions.add(products.byId(2)!);
    Get.find<HoldRecallController>().hold();
    for (final id in <int>[0, 1, 5]) {
      actions.add(products.byId(id)!);
    }
    final sale = testSale(
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
        ],
      ),
    );
    Get.find<SalesController>().sales.add(sale);
    final overlay = Get.find<OverlayController>();
    await tester.pump();

    Future<void> settle() async {
      await tester.pumpAndSettle();
      Get.find<ToastController>().toasts.clear();
    }

    void collect(String size, String screen, {bool dialog = false}) {
      final seen = <String>{};
      void add(String type, Element e, String label) {
        final box = e.renderObject;
        if (box is! RenderBox || !box.hasSize) return;
        final r = globalRect(box);
        final key =
            '${r.left.round()},${r.top.round()},${r.width.round()},'
            '${r.height.round()}';
        if (!seen.add(key)) return;
        // ignore: avoid_print
        print(
          'TOUCH|$size|$screen|$type|$label|${r.width.toStringAsFixed(1)}|'
          '${r.height.toStringAsFixed(1)}',
        );
      }

      void visit(Element e) {
        final w = e.widget;
        if (w is AppPressable && w.onTap != null) {
          add('pressable', e, _label(e));
        } else if (w is InkWell && w.onTap != null) {
          add('inkwell', e, _label(e));
        } else if (w is GestureDetector && w.onTap != null) {
          add('gesture', e, _label(e));
        } else if (w is Checkbox) {
          add('checkbox', e, _label(e));
        } else if (w is EditableText) {
          add('input', e, w.controller.text.isEmpty ? 'input' : 'input(text)');
        }
        e.visitChildren(visit);
      }

      if (!dialog) {
        tester.binding.rootElement!.visitChildren(visit);
        return;
      }
      // Only the dialog card itself (the page behind it is not tappable).
      for (final e in tester.elementList(
        find.byWidgetPredicate((w) => w is AppModal || w is AppDrawer),
      )) {
        visit(e);
      }
    }

    for (final size in _sizes) {
      useLogicalViewport(tester, size);
      await settle();
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      for (final route in <String>[
        AppRoutes.pos,
        AppRoutes.products,
        AppRoutes.customers,
        AppRoutes.sales,
        AppRoutes.returns,
        AppRoutes.reports,
        AppRoutes.more,
      ]) {
        if (Get.currentRoute != route) Get.offAllNamed<void>(route);
        await settle();
        if (route == AppRoutes.returns) {
          final page = Get.find<ReturnsController>();
          page.billNumber.text = 'AX000001';
          page.onBillChanged('AX000001');
          await settle();
        }
        _check(tester, size, '$route $tag');
        collect(tag, 'page $route');
      }
      if (Get.currentRoute != AppRoutes.pos) {
        Get.offAllNamed<void>(AppRoutes.pos);
      }
      await settle();
      for (final id in _dialogs) {
        if (id == 'confirm') {
          overlay.openConfirm('Confirm?', () {});
        } else {
          overlay.open(id, payload: id == 'receipt' ? sale : null);
        }
        await settle();
        _check(tester, size, '$id $tag');
        collect(tag, 'dialog $id', dialog: true);
        overlay.close();
        await settle();
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    await tester.pump(const Duration(seconds: 6));
  });
}
