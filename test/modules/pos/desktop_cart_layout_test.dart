// The six states of the desktop POS work area (DEC-141) at 1280x720, 1440x900
// and 1868x1035, light and dark: no overflow, panel widths in the stated
// ratios, Billing at its own width, the footer chip while Billing is closed,
// and a settled layout after every step.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/pos_work_view_controller.dart';
import 'package:pos_application/modules/pos/models/pos_panel_layout.dart';
import 'package:pos_application/modules/pos/widgets/billing_total_chip.dart';
import 'package:pos_application/modules/pos/widgets/cart_compact_row.dart';
import 'package:pos_application/modules/pos/widgets/cart_footer.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

const _sizes = <Size>[Size(1280, 720), Size(1440, 900), Size(1868, 1035)];

/// Products step, Billing open, and the Products : Cart ratio (null when one
/// of them is closed).
const _states = <(int, bool, double?)>[
  (0, true, null), // cart 75, today's cart view
  (25, true, 0.5), // all three
  (75, true, null), // cart 0, today's catalog view
  (0, false, null), // cart 100
  (25, false, 1 / 3),
  (75, false, 3),
];

Future<void> boot(
  WidgetTester tester,
  Size size, {
  required bool dark,
  int lines = 14,
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
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
  Get.find<ToastController>().toasts.clear();
  await tester.pumpAndSettle();
}

/// Moves the layout to [products] / [billing] through the public steps.
Future<void> goTo(WidgetTester tester, int products, bool billing) async {
  final work = Get.find<PosWorkViewController>();
  for (var i = 0; i < 4 && work.effective.products.percent < products; i++) {
    work.wider();
    await tester.pumpAndSettle();
  }
  for (var i = 0; i < 4 && work.effective.products.percent > products; i++) {
    work.narrower();
    await tester.pumpAndSettle();
  }
  if (work.effective.billing != billing) {
    work.toggleBilling();
    await tester.pumpAndSettle();
  }
}

Rect slot(WidgetTester tester, String name) =>
    tester.getRect(find.byKey(ValueKey<String>('pos-slot-$name')));

void main() {
  useTestApp();

  for (final size in _sizes) {
    for (final dark in <bool>[false, true]) {
      final name =
          '${size.width.toInt()}x${size.height.toInt()} '
          '${dark ? 'dark' : 'light'}';
      testWidgets('six states at $name', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          await boot(tester, size, dark: dark);
          expect(tester.takeException(), isNull);
          final work = Get.find<PosWorkViewController>();
          final billingWidth = AppMetrics(
            size,
            touch: false,
          ).summaryWidth(isPos: true);
          for (final (products, billing, ratio) in _states) {
            final label = 'P$products/B${billing ? 25 : 0} at $name';
            await goTo(tester, products, billing);
            expect(
              work.effective,
              PanelLayout(ProductsStep.fromPercent(products), billing: billing),
              reason: label,
            );
            expect(tester.takeException(), isNull, reason: label);

            final p = slot(tester, 'products');
            final c = slot(tester, 'cart');
            final b = slot(tester, 'billing');
            expect(
              b.width,
              closeTo(billing ? billingWidth : 0, 1),
              reason: label,
            );
            expect(p.width > 0, products > 0, reason: label);
            final cartPercent = 100 - products - (billing ? 25 : 0);
            expect(c.width > 0, cartPercent > 0, reason: label);
            if (ratio != null) {
              expect(
                c.width / p.width,
                closeTo(1 / ratio, 0.01),
                reason: label,
              );
            }
            // Panels sit in order and fill the work area to the right edge.
            if (products > 0 && cartPercent > 0) {
              expect(c.left - p.right, closeTo(16, 1), reason: label);
            }
            final rightmost = billing ? b : (cartPercent > 0 ? c : p);
            expect(rightmost.right, closeTo(size.width - 16, 1), reason: label);
            // The footer chip stands in for a closed Billing.
            expect(
              find.byType(BillingTotalChip).evaluate().length,
              billing || cartPercent == 0 ? 0 : 1,
              reason: label,
            );
            if (cartPercent > 0) {
              expect(find.byType(CartFooter), findsOneWidget, reason: label);
              expect(find.byType(CartCompactRow), findsWidgets, reason: label);
            }
          }
          await tester.pump(const Duration(seconds: 6));
          await tester.pumpAndSettle();
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }

  for (final size in const <Size>[
    Size(900, 600),
    Size(950, 733),
    Size(1100, 700),
    Size(1500, 900),
  ]) {
    testWidgets('every reachable state reads without overflow at '
        '${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await boot(tester, size, dark: false, lines: 6);
        final work = Get.find<PosWorkViewController>();
        for (final (products, billing, _) in _states) {
          await goTo(tester, products, billing);
          expect(
            tester.takeException(),
            isNull,
            reason: 'P$products/B${billing ? 25 : 0} -> ${work.effective}',
          );
        }
        // Steps through the whole cycle, each one settled.
        for (var i = 0; i < 4; i++) {
          work.cycleProducts();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '${work.effective}');
        }
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  testWidgets('mid-transition the panels share the work width', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await boot(tester, const Size(1280, 720), dark: false, lines: 3);
      final work = Get.find<PosWorkViewController>();
      final before = slot(tester, 'cart').width;
      work.wider();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      final p = slot(tester, 'products');
      final c = slot(tester, 'cart');
      final b = slot(tester, 'billing');
      expect(p.width, greaterThan(0));
      expect(c.width, lessThan(before));
      expect(c.width, greaterThan(0));
      // Everything still ends at the right edge while it moves.
      expect(b.right, closeTo(1280 - 16, 1));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the default cart view keeps today\'s rows and slim footer', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await boot(tester, const Size(1280, 720), dark: false);
      expect(tester.getSize(find.byType(CartCompactRow).first).height, 48);
      expect(
        tester.getSize(find.byType(CartFooter)).height,
        lessThanOrEqualTo(50),
      );
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
