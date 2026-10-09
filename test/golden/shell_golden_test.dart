// Shell goldens. Light at the reference viewport is compared (by eye) with
// reference_screenshots/; other sizes and dark are regression only.

@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';
import 'package:pos_application/main.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/modules/shift/controllers/shift_controller.dart';
import 'package:pos_application/shared/controllers/clock_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/discount_form_controller.dart';
import 'package:pos_application/modules/pos/controllers/global_search_controller.dart';
import 'package:pos_application/modules/pos/controllers/order_menu_controller.dart';
import 'package:pos_application/modules/pos/controllers/payment_controller.dart';
import 'package:pos_application/modules/pos/controllers/price_check_controller.dart';
import 'package:pos_application/modules/pos/models/payment_state.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';
import 'package:pos_application/modules/pos/controllers/held_bills_controller.dart';
import 'package:pos_application/modules/pos/models/held_bill.dart';

import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/returns/controllers/returns_controller.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';

import '../support/sale_fixtures.dart';
import '../support/test_app.dart';
import 'images.dart';
import 'harness.dart';

Future<void> _pump(
  WidgetTester tester, {
  required String route,
  bool dark = false,
  Size? logicalSize,
  Future<void> Function(WidgetTester tester)? after,
}) async {
  if (logicalSize == null) {
    useReferenceViewport(tester);
  } else {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = logicalSize;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  final binding = await bootInWidgetTest(tester);
  AppTypography.useBundledFonts = true;
  // A fixed clock (the reference screenshot shows 07/10/2026 16:57:08).
  Get.delete<ClockController>(force: true);
  Get.put<ClockController>(
    ClockController(now: () => DateTime(2026, 10, 7, 16, 57, 8)),
    permanent: true,
  );
  Get.delete<ShiftController>(force: true);
  Get.put<ShiftController>(
    ShiftController(
      sales: Get.find(),
      clock: Get.find(),
      overlay: Get.find(),
      search: Get.find(),
    ),
    permanent: true,
  );
  if (dark) {
    await tester.runAsync(() => Get.find<SettingsController>().setDark(true));
  }
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  await settleImages(tester);
  if (route != AppRoutes.pos) {
    Get.offAllNamed<void>(route);
    await tester.pumpAndSettle();
  }
  await after?.call(tester);
}

void main() {
  useTolerantGoldens();
  useTestApp();

  final skipReason = fontsSkipReason();
  final skip = skipReason.isNotEmpty;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!skip) await loadTestFonts();
  });
  final prefix = skip ? '[$skipReason] ' : '';

  // The reference screenshots are from macOS (the shortcut chip reads the
  // glyph). Foundation debug vars must be reset inside the test body.
  void golden(
    String name,
    String file, {
    String route = AppRoutes.pos,
    bool dark = false,
    Size? size,
    Future<void> Function(WidgetTester tester)? after,
  }) {
    testWidgets('$prefix$name', (tester) async {
      useRealShadows();
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await _pump(
          tester,
          route: route,
          dark: dark,
          logicalSize: size,
          after: after,
        );
        await expectLater(
          find.byType(PosApp),
          matchesGoldenFile('goldens/$file.png'),
        );
      } finally {
        if (Get.isRegistered<ToastController>()) {
          Get.find<ToastController>().onClose(); // cancel pending timers
        }
        debugDefaultTargetPlatformOverride = null;
        restoreDefaultShadows();
      }
    }, skip: skip);
  }

  Future<void> addLays(WidgetTester tester) async {
    final lays = Get.find<ProductsController>().byId(5)!;
    Get.find<CartActionsController>().add(lays);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2)); // highlight ends
    Get.find<ToastController>().toasts.clear();
    await tester.pumpAndSettle();
    await settleImages(tester);
  }

  golden('POS light, reference viewport', 'shell_pos_light');
  golden(
    'Products light, reference viewport',
    'shell_products_light',
    route: AppRoutes.products,
    after: addLays,
  );
  golden(
    'Customers light, reference viewport',
    'shell_customers_light',
    route: AppRoutes.customers,
    after: addLays,
  );
  golden(
    'Sales empty light, reference viewport',
    'shell_sales_light',
    route: AppRoutes.sales,
    after: addLays,
  );
  golden(
    'Reports zeros light, reference viewport',
    'shell_reports_light',
    route: AppRoutes.reports,
    after: addLays,
  );
  golden(
    'Returns empty light, reference viewport',
    'shell_returns_light',
    route: AppRoutes.returns,
    after: addLays,
  );
  golden(
    'Returns matched bill light (unverified visually)',
    'shell_returns_matched_light',
    route: AppRoutes.returns,
    after: (tester) async {
      final products = Get.find<ProductsController>();
      Get.find<SalesController>().sales.add(
        testSale(
          number: 'AX000007',
          at: DateTime(2026, 10, 7, 16, 50),
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
                discount: Bp.zero,
              ),
            ],
          ),
        ),
      );
      final page = Get.find<ReturnsController>();
      page.billNumber.text = 'AX000007';
      page.onBillChanged('AX000007');
      page.fieldFor(0).text = '1';
      page.onQtyChanged(0, '1');
      await tester.pumpAndSettle();
    },
  );
  golden(
    'Settings page light (unverified visually)',
    'shell_settings_light',
    route: AppRoutes.more,
  );
  golden(
    'Profile dialog light (unverified visually)',
    'dialog_profile_light',
    after: (tester) async {
      Get.find<OverlayController>().open('profile');
      await tester.pumpAndSettle();
    },
  );
  golden(
    'Shift close dialog light (unverified visually)',
    'dialog_shift_close_light',
    after: (tester) async {
      Get.find<OverlayController>().open('close');
      await tester.pumpAndSettle();
    },
  );
  golden(
    'Counter closed light (unverified visually)',
    'shell_signed_out_light',
    after: (tester) async {
      Get.find<ShiftController>().closeCounter();
      await tester.pumpAndSettle();
    },
  );
  golden(
    'Dialog and toast over POS (unverified visually)',
    'shell_dialog_toast',
    after: (tester) async {
      Get.find<OverlayController>().open('unregistered');
      Get.find<ToastController>().show('Store switched');
      await tester.pumpAndSettle();
    },
  );
  golden(
    'POS with one line (Lays Classic), reference viewport',
    'pos_one_line_light',
    after: addLays,
  );
  for (final size in const <Size>[
    Size(1440, 900),
    Size(1100, 700),
    Size(950, 733),
  ]) {
    final w = size.width.toInt();
    golden(
      'POS with one line at ${w}x${size.height.toInt()} '
          '(regression, unverified visually)',
      'pos_one_line_light_$w',
      size: size,
      after: addLays,
    );
  }
  Future<void> holdTwo(WidgetTester tester) async {
    final cart = Get.find<CartController>();
    final held = Get.find<HeldBillsController>();
    final products = Get.find<ProductsController>();
    for (final (ref, id) in <(String, int)>[('H482913', 5), ('H482977', 1)]) {
      Get.find<CartActionsController>().add(products.byId(id)!);
      // A local time without zone: the golden does not depend on the machine.
      held.bills.add(
        HeldBill(
          ref: ref,
          time: '2026-10-07T16:57:08.000',
          cart: cart.cart.value,
        ),
      );
      cart.clear();
    }
    await tester.pump(const Duration(seconds: 2)); // highlight ends
    Get.find<ToastController>().toasts.clear();
    await tester.pump();
  }

  golden(
    'Held bills dialog (regression, unverified visually)',
    'recall_dialog_light',
    after: (tester) async {
      await holdTwo(tester);
      Get.find<OverlayController>().open('recall');
      await tester.pumpAndSettle();
    },
  );
  golden(
    'Bill discount drawer (regression, unverified visually)',
    'discount_drawer_light',
    after: (tester) async {
      await addLays(tester);
      Get.find<DiscountFormController>().open();
      await tester.pumpAndSettle();
    },
  );
  golden(
    'Search results dropdown (regression, unverified visually)',
    'search_results_light',
    after: (tester) async {
      Get.find<SearchFieldController>().text.text = 'a';
      Get.find<GlobalSearchController>().refreshNow();
      await tester.pumpAndSettle();
    },
  );
  golden(
    'Scan simulator (regression, unverified visually)',
    'scan_dialog_light',
    after: (tester) async {
      Get.find<OverlayController>().open('scan');
      await tester.pumpAndSettle();
    },
  );
  golden(
    'Price check with a result (regression, unverified visually)',
    'price_check_light',
    after: (tester) async {
      Get.find<OverlayController>().open('priceCheck');
      await tester.pumpAndSettle();
      final check = Get.find<PriceCheckController>();
      check.text.text = 'bdv001';
      check.onChanged('bdv001');
      await tester.pumpAndSettle();
    },
  );
  golden(
    'Customer picker (regression, unverified visually)',
    'customer_picker_light',
    after: (tester) async {
      Get.find<OverlayController>().open('customers');
      await tester.pumpAndSettle();
    },
  );
  golden(
    'Add customer (regression, unverified visually)',
    'add_customer_light',
    after: (tester) async {
      Get.find<OverlayController>().open('addCustomer');
      await tester.pumpAndSettle();
    },
  );
  golden(
    'Receipt after a cash payment (regression, unverified visually)',
    'receipt_light',
    after: (tester) async {
      await addLays(tester);
      final pay = Get.find<PaymentController>();
      pay.payment(PaymentMode.cash);
      await tester.pump();
      pay.tendered.text = '50';
      pay.completeCash();
      await tester.pumpAndSettle();
      Get.find<ToastController>().toasts.clear();
      await tester.pump();
    },
  );
  golden(
    'Receipt draft (regression, unverified visually)',
    'receipt_draft_light',
    after: (tester) async {
      await addLays(tester);
      Get.find<OrderMenuController>().printDraft();
      await tester.pumpAndSettle();
    },
  );
  golden(
    'Reprint list (regression, unverified visually)',
    'reprint_light',
    after: (tester) async {
      await addLays(tester);
      final pay = Get.find<PaymentController>();
      pay.payment(PaymentMode.cash);
      await tester.pump();
      pay.tendered.text = '50';
      pay.completeCash();
      await tester.pumpAndSettle();
      Get.find<OverlayController>().open('reprint');
      Get.find<ToastController>().toasts.clear();
      await tester.pumpAndSettle();
    },
  );
  golden(
    'Rename counter (regression, unverified visually)',
    'counter_dialog_light',
    after: (tester) async {
      Get.find<OrderMenuController>().renameCounter();
      await tester.pumpAndSettle();
    },
  );
  golden(
    'Keyboard shortcuts (regression, unverified visually)',
    'shortcuts_light',
    after: (tester) async {
      Get.find<OverlayController>().open('shortcuts');
      await tester.pumpAndSettle();
    },
  );
  golden('POS dark (unverified visually)', 'shell_pos_dark', dark: true);
  for (final size in const <Size>[
    Size(1700, 960),
    Size(1280, 800),
    Size(1100, 700),
  ]) {
    final w = size.width.toInt();
    golden(
      'POS light at ${w}x${size.height.toInt()} (regression)',
      'shell_pos_light_$w',
      size: size,
    );
  }
}
