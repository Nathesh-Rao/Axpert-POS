// The desktop POS work area shows ONE view at a time (DEC-139): the catalog
// (always with an empty cart) or the cart. Transitions, the edge tab, Ctrl and
// Cmd+B, Escape, focus and the touch layout.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/held_bills_controller.dart';
import 'package:pos_application/modules/pos/controllers/hold_recall_controller.dart';
import 'package:pos_application/modules/pos/controllers/payment_controller.dart';
import 'package:pos_application/modules/pos/controllers/pos_work_view_controller.dart';
import 'package:pos_application/modules/pos/models/payment_state.dart';
import 'package:pos_application/modules/pos/widgets/cart_compact_row.dart';
import 'package:pos_application/modules/pos/widgets/catalog_panel.dart';
import 'package:pos_application/modules/pos/widgets/desktop_cart_column.dart';
import 'package:pos_application/modules/pos/widgets/stat_tiles.dart';
import 'package:pos_application/modules/pos/widgets/work_tab.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

Future<void> _boot(
  WidgetTester tester, {
  Size size = const Size(1280, 720),
}) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  useLogicalViewport(tester, size);
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
}

Future<void> _finish(WidgetTester tester) async {
  Get.find<ToastController>().toasts.clear();
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
  debugDefaultTargetPlatformOverride = null;
}

PosWorkViewController get _work => Get.find<PosWorkViewController>();

double _width(WidgetTester tester, Finder f) => tester.getSize(f).width;

Future<void> _key(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  LogicalKeyboardKey? modifier,
}) async {
  if (modifier != null) await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(key);
  if (modifier != null) await tester.sendKeyUpEvent(modifier);
  await tester.pumpAndSettle();
}

Finder _addTooltip(String name) => find.byWidgetPredicate(
  (w) => w is Tooltip && (w.message ?? '').startsWith('Add $name'),
);

Future<void> _searchAdd(WidgetTester tester, String text) async {
  final search = Get.find<SearchFieldController>();
  search.focusNode.requestFocus();
  await tester.pump();
  await tester.enterText(
    find.byWidgetPredicate(
      (w) => w is TextField && w.controller == search.text,
    ),
    text,
  );
  await tester.pump(const Duration(milliseconds: 200));
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

Future<void> _tapTab(WidgetTester tester) async {
  await tester.tap(find.byType(WorkTab));
  await tester.pumpAndSettle();
}

void main() {
  useTestApp();

  testWidgets('an empty cart shows the catalog over the whole work area', (
    tester,
  ) async {
    try {
      await _boot(tester);
      expect(_work.view, PosWorkView.catalog);
      expect(find.byType(WorkTab), findsOneWidget);
      expect(find.byType(CatalogPanel), findsOneWidget);
      // The cart pane is hidden: no width, no focus, no semantics.
      expect(
        _width(tester, find.byType(DesktopCartColumn)),
        1280 > 0 ? greaterThan(0) : 0,
      );
      final catalog = tester.getRect(find.byType(CatalogPanel));
      final tab = tester.getRect(find.byType(WorkTab));
      expect(catalog.left, greaterThan(tab.right));
      expect(find.byType(StatTiles), findsNothing);
      // With an empty cart the tab cannot switch.
      await _tapTab(tester);
      expect(_work.view, PosWorkView.catalog);
      await _key(
        tester,
        LogicalKeyboardKey.keyB,
        modifier: LogicalKeyboardKey.controlLeft,
      );
      expect(_work.view, PosWorkView.catalog);
      // Escape with an empty cart does nothing.
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_work.view, PosWorkView.catalog);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('adding through the search box switches to the cart', (
    tester,
  ) async {
    try {
      await _boot(tester);
      await _searchAdd(tester, 'cola');
      expect(Get.find<CartController>().cart.value.lines, hasLength(1));
      expect(_work.view, PosWorkView.cart);
      expect(find.byType(CartCompactRow), findsOneWidget);
      // The search keeps the focus: the next scan goes into it.
      expect(Get.find<SearchFieldController>().focusNode.hasFocus, isTrue);
      // Back in the catalog by hand; a search add shows the cart again.
      await _tapTab(tester);
      expect(_work.view, PosWorkView.catalog);
      await _searchAdd(tester, 'pepsi');
      expect(_work.view, PosWorkView.cart);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('a tile click adds and stays in the catalog; the tab counts', (
    tester,
  ) async {
    try {
      await _boot(tester);
      await tester.tap(_addTooltip('Coca Cola 500ml').first);
      await tester.pump();
      expect(_work.view, PosWorkView.catalog);
      await tester.tap(_addTooltip('Pepsi 500ml').first);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(Get.find<CartController>().cart.value.lines, hasLength(2));
      expect(_work.view, PosWorkView.catalog, reason: 'picks in a row');
      expect(find.text('Cart (2)'), findsOneWidget);
      expect(_work.pulse.value, 2);
      // Switch to the cart: the tab now reads Products.
      await _tapTab(tester);
      expect(_work.view, PosWorkView.cart);
      expect(
        find.descendant(
          of: find.byType(WorkTab),
          matching: find.text('Products'),
        ),
        findsOneWidget,
      );
      expect(find.byType(CartCompactRow), findsNWidgets(2));
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('the tab and Ctrl+B / Cmd+B toggle with items in the cart', (
    tester,
  ) async {
    try {
      await _boot(tester);
      await _searchAdd(tester, 'cola');
      await _key(
        tester,
        LogicalKeyboardKey.keyB,
        modifier: LogicalKeyboardKey.controlLeft,
      );
      expect(_work.view, PosWorkView.catalog);
      await _key(
        tester,
        LogicalKeyboardKey.keyB,
        modifier: LogicalKeyboardKey.metaLeft,
      );
      expect(_work.view, PosWorkView.cart);
      await _tapTab(tester);
      expect(_work.view, PosWorkView.catalog);
      // Escape returns from the catalog to the cart.
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_work.view, PosWorkView.cart);
      // Escape in the cart changes nothing.
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_work.view, PosWorkView.cart);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('Escape closes a dialog first, then returns to the cart', (
    tester,
  ) async {
    try {
      await _boot(tester);
      await _searchAdd(tester, 'cola');
      await _tapTab(tester);
      Get.find<OverlayController>().open('priceCheck');
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.escape);
      expect(Get.find<OverlayController>().isOpen, isFalse);
      expect(_work.view, PosWorkView.catalog, reason: 'the dialog first');
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_work.view, PosWorkView.cart);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('focus: the search box in the catalog, the cart list in the '
      'cart', (tester) async {
    try {
      await _boot(tester);
      await _searchAdd(tester, 'cola');
      await _tapTab(tester); // catalog
      await tester.pump();
      expect(Get.find<SearchFieldController>().focusNode.hasFocus, isTrue);
      await _tapTab(tester); // cart
      await tester.pump();
      expect(_work.cartFocus.hasFocus, isTrue);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('clearing the cart, holding the last bill and checkout return '
      'to the catalog; recall shows the cart', (tester) async {
    try {
      await _boot(tester);
      final cart = Get.find<CartController>();
      final products = Get.find<ProductsController>();
      final actions = Get.find<CartActionsController>();

      // Clear.
      await _searchAdd(tester, 'cola');
      expect(_work.view, PosWorkView.cart);
      actions.clear();
      await tester.pumpAndSettle();
      expect(cart.active.value, isFalse);
      expect(_work.view, PosWorkView.catalog);

      // Hold the last bill, then recall it.
      actions.add(products.products[1]);
      _work.showCart();
      await tester.pumpAndSettle();
      expect(_work.view, PosWorkView.cart);
      Get.find<HoldRecallController>().hold();
      await tester.pumpAndSettle();
      expect(_work.view, PosWorkView.catalog);
      final bill = Get.find<HeldBillsController>().bills.first;
      await _tapTab(tester); // nothing to switch to
      Get.find<HoldRecallController>().recall(bill);
      await tester.pumpAndSettle();
      expect(_work.view, PosWorkView.cart);

      // Checkout.
      final pay = Get.find<PaymentController>();
      pay.payment(PaymentMode.cash);
      await tester.pump();
      pay.tendered.text = '500';
      pay.completeCash();
      await tester.pumpAndSettle();
      expect(cart.active.value, isFalse);
      expect(_work.view, PosWorkView.catalog);
      expect(find.byType(CatalogPanel), findsOneWidget);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('the tab carries semantics for every state', (tester) async {
    try {
      await _boot(tester);
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel(RegExp('Cart, empty')), findsOneWidget);
      await _searchAdd(tester, 'cola');
      expect(
        find.bySemanticsLabel(RegExp('Show products, press Ctrl\\+B')),
        findsOneWidget,
      );
      await _tapTab(tester);
      expect(
        find.bySemanticsLabel(RegExp('Show the cart, 1 items, press Ctrl\\+B')),
        findsOneWidget,
      );
      handle.dispose();
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('the view change is instant under disableAnimations', (
    tester,
  ) async {
    try {
      await _boot(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await _searchAdd(tester, 'cola');
      final before = tester.getRect(find.byType(DesktopCartColumn));
      await tester.tap(find.byType(WorkTab));
      await tester.pump(); // one frame, no settle
      await tester.pump();
      expect(_work.view, PosWorkView.catalog);
      expect(_width(tester, find.byType(CatalogPanel)), before.width);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('the touch layout keeps the catalog, the cart column and the '
      'stat tiles', (tester) async {
    // Android is the flutter_test default: today's layout.
    useLogicalViewport(tester, const Size(1280, 720));
    final binding = await bootInWidgetTest(tester);
    await tester.pumpWidget(testApp(binding));
    await tester.pumpAndSettle();
    expect(find.byType(WorkTab), findsNothing);
    expect(find.byType(CatalogPanel), findsOneWidget);
    Get.find<CartActionsController>().add(
      Get.find<ProductsController>().products.first,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(StatTiles), findsOneWidget);
    expect(find.byType(CartCompactRow), findsNothing);
    Get.find<ToastController>().toasts.clear();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });
}
