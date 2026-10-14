// Route and dialog navigation from a REAL state (standing check, added after
// the Reports/Customers "markNeedsBuild() called during build" bug that only
// showed in a debug build): a cart with items, a customer with points selected,
// customers and sales (with lines) stored. Every sidebar page is opened from
// POS and from the previous page, every dialog is opened and closed on POS and
// on Reports. After EVERY step: no framework error was reported (all of them
// are collected, not only the first), no ErrorWidget is on screen and the
// GetX proxy is not left pointing at an Obx whose builder threw.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/features/session/data/in_memory_session_repositories.dart';
import 'package:pos_application/features/session/domain/entities/session_entities.dart';
import 'package:pos_application/features/session/presentation/controllers/active_session.dart';
import '../support/test_session.dart';
import '../support/seed/seed_customers.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/pos_work_view_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_meta_controller.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
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

  // Touch (the flutter_test default, the prototype layout) and desktop (the
  // cart-first layout of DEC-138) both run the same walk.
  for (final desktop in <bool>[false, true]) {
    testWidgets('every page and dialog from a real state raises no error '
        '(${desktop ? 'desktop' : 'touch'} layout)', (tester) async {
      if (desktop) debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
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
                .descendant(
                  of: find.byType(Sidebar),
                  matching: find.byTooltip(label),
                )
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
        // The three-panel layout (DEC-141): every Products step with Billing
        // open and collapsed, the cycle, then dialogs over a layout that is
        // not the default.
        if (desktop) {
          await tapPage('POS');
          final work = Get.find<PosWorkViewController>();
          for (final billing in <bool>[true, false]) {
            if (work.effective.billing != billing) work.toggleBilling();
            await tester.pumpAndSettle();
            check('billing ${billing ? 'open' : 'closed'}');
            for (var i = 0; i < 4; i++) {
              work.cycleProducts();
              await tester.pumpAndSettle();
              check('cycle ${work.effective} (billing $billing)');
            }
          }
          work.wider();
          await tester.pumpAndSettle();
          Get.find<OverlayController>().open('priceCheck');
          await tester.pumpAndSettle();
          check('dialog over ${work.effective}');
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          check('closed over ${work.effective}');
        }
        await tester.pump(const Duration(seconds: 6));
        check('end');
      } finally {
        FlutterError.onError = previous;
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  testWidgets('store and counter picker raises no error', (tester) async {
    useLogicalViewport(tester, const Size(1280, 720));
    final session = ActiveSession.fixed(
      user: testUser,
      store: testAccess.first.store,
      counter: testAccess.first.counters.first,
      access: const <StoreAccess>[],
      quickCash: const <String, List<int>>{},
      users: InMemoryUserRepository(
        users: <UserCredential>[testCredential],
        access: <String, List<StoreAccess>>{testUser.id: testAccess},
      ),
    );
    final binding = await bootInWidgetTest(
      tester,
      store: _seededStore(),
      session: session,
    );
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exceptionAsString());
    try {
      void check(String step) {
        expect(errors, isEmpty, reason: 'errors after "$step": $errors');
        expect(find.byType(ErrorWidget), findsNothing, reason: step);
        expect(RxInterface.proxy, isNull, reason: step);
      }

      await tester.pumpWidget(testApp(binding, initialRoute: '/splash'));
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(seconds: 2));
      await tester.enterText(find.byType(TextField).first, 'cashier');
      await tester.enterText(find.byType(TextField).last, 'secret');
      await tester.tap(find.text('Sign In'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      check('login to picker');
      expect(find.text('Choose store and counter'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      check('picker to landing');
      Get.find<ToastController>().toasts.clear();
      await tester.pump(const Duration(milliseconds: 100));
    } finally {
      FlutterError.onError = previous;
    }
  });

  testWidgets('entry flow (splash, login, landing) raises no error', (
    tester,
  ) async {
    useLogicalViewport(tester, const Size(1280, 720));
    final binding = await bootInWidgetTest(tester, store: _seededStore());
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details.exceptionAsString());
    try {
      void check(String step) {
        expect(errors, isEmpty, reason: 'errors after "$step": $errors');
        expect(find.byType(ErrorWidget), findsNothing, reason: step);
        expect(RxInterface.proxy, isNull, reason: step);
      }

      await tester.pumpWidget(testApp(binding, initialRoute: '/splash'));
      await tester.pump(const Duration(milliseconds: 1000));
      check('splash');
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(seconds: 2));
      check('splash to login');
      expect(find.text('Welcome Back'), findsOneWidget);
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      check('empty submit');
      await tester.enterText(find.byType(TextField).first, 'cashier');
      await tester.enterText(find.byType(TextField).last, 'secret');
      await tester.tap(find.text('Sign In'));
      await tester.pump(const Duration(milliseconds: 300));
      check('loading');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      check('login to landing');
      expect(find.text('Welcome Back'), findsNothing);
      Get.find<ToastController>().toasts.clear();
      await tester.pump(const Duration(milliseconds: 100));
    } finally {
      FlutterError.onError = previous;
    }
  });
}
