// Route and dialog navigation from a REAL state (standing check, added after
// the Reports/Customers "markNeedsBuild() called during build" bug that only
// showed in a debug build): a cart with items, a customer with points selected,
// customers and sales (with lines) stored. Every sidebar page is opened from
// POS and from the previous page, every dialog is opened and closed on POS and
// on Reports. After EVERY step: no framework error was reported (all of them
// are collected, not only the first), no ErrorWidget is on screen and the
// GetX proxy is not left pointing at an Obx whose builder threw.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/mock/seed_customers.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_meta_controller.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/modules/shell/widgets/sidebar.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

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

const List<String> _pages = <String>[
  'POS',
  'Products',
  'Customers',
  'Sales',
  'Returns',
  'Reports',
  'More',
];

InMemoryLocalStore _seededStore() {
  final store = InMemoryLocalStore();
  final customers = <Customer>[
    ...SeedCustomers.customers,
    const Customer(
      id: '9',
      name: 'Venkat Rao',
      phone: '9876543299',
      email: 'venkat@example.com',
      member: 'MG1009',
      points: 90,
    ),
  ];
  store.write(StorageKeys.customers, <Map<String, dynamic>>[
    for (final c in customers) c.toJson(),
  ]);
  return store;
}

void main() {
  useTestApp();

  testWidgets('every page and dialog from a real state raises no error', (
    tester,
  ) async {
    useLogicalViewport(tester, const Size(1280, 720));
    final store = _seededStore();
    final binding = await bootInWidgetTest(tester, store: store);
    await tester.pumpWidget(testApp(binding));
    await tester.pumpAndSettle();

    // Stored sales with lines, a cart with 3 items, Priya Nair (400 points).
    final products = Get.find<ProductsController>();
    final sale = testSale(
      number: 'AX000001',
      at: DateTime.now(),
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
    await tester.runAsync(() async {
      await store.write(StorageKeys.sales, <Map<String, dynamic>>[
        sale.toJson(),
      ]);
    });
    final actions = Get.find<CartActionsController>();
    for (final id in <int>[5, 6, 7]) {
      actions.add(products.byId(id)!);
    }
    Get.find<CartMetaController>().setCustomer('3');
    await tester.pump();
    Get.find<ToastController>().toasts.clear();
    await tester.pumpAndSettle();

    // Collect EVERY framework error, not only the first one.
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(
        '${details.exceptionAsString().split('\n').first}\n${details.stack}',
      );
    };

    try {
      void check(String step) {
        expect(
          errors,
          isEmpty,
          reason: 'errors after "$step":\n${errors.join('\n--\n')}',
        );
        expect(
          find.byType(ErrorWidget),
          findsNothing,
          reason: 'error widget after "$step"',
        );
        expect(
          RxInterface.proxy,
          isNull,
          reason: 'GetX proxy left set after "$step"',
        );
      }

      Future<void> tapPage(String label) async {
        await tester.tap(
          find
              .descendant(of: find.byType(Sidebar), matching: find.text(label))
              .first,
        );
        await tester.pumpAndSettle();
        Get.find<ToastController>().toasts.clear();
        await tester.pump(const Duration(milliseconds: 100));
      }

      check('start on POS');
      expect(find.text('Priya Nair'), findsWidgets);

      // Each page from POS and back.
      for (final page in _pages.skip(1)) {
        await tapPage(page);
        check('POS -> $page');
        await tapPage('POS');
        check('$page -> POS');
      }
      // Reports first, then every other page straight from Reports (the order
      // that showed the red Customers screen in the debug build).
      for (final page in _pages.where((p) => p != 'POS' && p != 'Reports')) {
        await tapPage('Reports');
        check('POS -> Reports (before $page)');
        await tapPage(page);
        check('Reports -> $page');
        await tapPage('POS');
        check('$page -> POS (after Reports)');
      }
      // Each page from the previous page (no POS in between), forward and back.
      for (final page in _pages.skip(1)) {
        await tapPage(page);
        check('-> $page (chain)');
      }
      for (final page in _pages.reversed.skip(1)) {
        await tapPage(page);
        check('-> $page (reverse chain)');
      }

      // Dialogs on POS (cart state) and on Reports (clock attached).
      for (final home in <String>['POS', 'Reports']) {
        if (home != 'POS') await tapPage(home);
        check('page $home');
        for (final id in _dialogs) {
          final overlay = Get.find<OverlayController>();
          if (id == 'confirm') {
            overlay.openConfirm('Confirm?', () {});
          } else {
            overlay.open(id, payload: id == 'receipt' ? sale : null);
          }
          await tester.pumpAndSettle();
          check('$id dialog open on $home');
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          Get.find<ToastController>().toasts.clear();
          await tester.pump(const Duration(milliseconds: 100));
          check('$id dialog closed on $home');
          expect(overlay.isOpen, isFalse, reason: id);
        }
      }
      await tester.pump(const Duration(seconds: 6));
      check('end');
    } finally {
      FlutterError.onError = previous;
    }
  });
}
