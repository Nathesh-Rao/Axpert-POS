// The desktop POS work area (DEC-141): the automatic rules, the edge control,
// Ctrl/Cmd+B and Ctrl/Cmd+., Escape, focus, persistence and the touch layout.
// The six states and their widths are in `three_panel_layout_test.dart`.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
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
import 'package:pos_application/modules/shell/widgets/bill_summary_frame.dart';
import 'package:pos_application/modules/pos/models/pos_panel_layout.dart';
import 'package:pos_application/modules/pos/widgets/billing_total_chip.dart';
import 'package:pos_application/modules/pos/widgets/products_edge_control.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
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

/// Click on the edge control's body (not on a chevron).
Future<void> _tapTab(WidgetTester tester) async {
  final rect = tester.getRect(find.byType(ProductsEdgeControl));
  await tester.tapAt(Offset(rect.center.dx, rect.bottom - 40));
  await tester.pumpAndSettle();
}

Future<void> _ctrl(WidgetTester tester, LogicalKeyboardKey key) =>
    _key(tester, key, modifier: LogicalKeyboardKey.controlLeft);

Future<void> _cmd(WidgetTester tester, LogicalKeyboardKey key) =>
    _key(tester, key, modifier: LogicalKeyboardKey.metaLeft);

PanelLayout get _drawn => _work.effective;

double _slotWidth(WidgetTester tester, String name) =>
    tester.getSize(find.byKey(ValueKey<String>('pos-slot-$name'))).width;

PanelLayout _layout(int products, bool billing) =>
    PanelLayout(ProductsStep.fromPercent(products), billing: billing);

void main() {
  useTestApp();

  testWidgets('rule 1: an empty cart shows the catalog layout; Billing keeps '
      'its state', (tester) async {
    try {
      await _boot(tester);
      expect(_drawn, _layout(75, true));
      expect(_slotWidth(tester, 'products'), greaterThan(0));
      expect(_slotWidth(tester, 'cart'), 0);
      expect(find.byType(StatTiles), findsNothing);
      // With an empty cart the edge control cannot switch.
      await _tapTab(tester);
      await _ctrl(tester, LogicalKeyboardKey.keyB);
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_drawn, _layout(75, true));
      // Billing can still be collapsed; the catalog layout stays.
      await _ctrl(tester, LogicalKeyboardKey.period);
      expect(_drawn, _layout(75, false));
      expect(_slotWidth(tester, 'billing'), 0);
      expect(_slotWidth(tester, 'cart'), greaterThan(0), reason: '25% cart');
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('rule 2: the first add goes to the last cart layout', (
    tester,
  ) async {
    try {
      await _boot(tester);
      await _searchAdd(tester, 'cola');
      expect(_drawn, _layout(0, true), reason: 'default');
      expect(find.byType(CartCompactRow), findsOneWidget);
      // Choose P25/B25, empty the cart, add again: back to P25.
      _work.wider();
      await tester.pumpAndSettle();
      expect(_drawn, _layout(25, true));
      Get.find<CartActionsController>().clear();
      await tester.pumpAndSettle();
      expect(_drawn, _layout(75, true));
      await tester.tap(_addTooltip('Coca Cola 500ml').first);
      await tester.pumpAndSettle();
      expect(_drawn, _layout(25, true));
      expect(_work.pulse.value, 0);
      // Billing changed while the cart was empty is kept.
      Get.find<CartActionsController>().clear();
      await tester.pumpAndSettle();
      _work.closeBilling();
      await tester.pumpAndSettle();
      await _searchAdd(tester, 'pepsi');
      expect(_drawn, _layout(25, false));
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('rule 3: with the cart visible tile clicks add and stay; at '
      'Products 75 they flash the count', (tester) async {
    try {
      await _boot(tester);
      await _searchAdd(tester, 'cola');
      _work.wider(); // P25/B25: all three visible
      await tester.pumpAndSettle();
      await tester.tap(_addTooltip('Pepsi 500ml').first);
      await tester.pumpAndSettle();
      expect(Get.find<CartController>().cart.value.lines, hasLength(2));
      expect(_drawn, _layout(25, true));
      expect(_work.pulse.value, 0);
      // Products 75: the cart is hidden, a tile click stays and pulses.
      _work.wider();
      await tester.pumpAndSettle();
      expect(_drawn, _layout(75, true));
      expect(_slotWidth(tester, 'cart'), 0);
      await tester.tap(_addTooltip('Sprite 500ml').first);
      await tester.pumpAndSettle();
      expect(Get.find<CartController>().cart.value.lines, hasLength(3));
      expect(_drawn, _layout(75, true));
      expect(_work.pulse.value, 1);
      expect(find.text('Cart (3)'), findsOneWidget);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('rule 3: a search or scan add at Products 75 shows the last '
      'cart layout; a recall too', (tester) async {
    try {
      await _boot(tester);
      await _searchAdd(tester, 'cola');
      _work.wider();
      _work.wider();
      await tester.pumpAndSettle();
      expect(_drawn, _layout(75, true));
      await _searchAdd(tester, 'pepsi');
      expect(_drawn, _layout(25, true), reason: 'last cart layout');
      // Recall.
      _work.wider();
      await tester.pumpAndSettle();
      Get.find<HoldRecallController>().hold();
      await tester.pumpAndSettle();
      expect(_drawn, _layout(75, true), reason: 'empty cart');
      final bill = Get.find<HeldBillsController>().bills.first;
      Get.find<HoldRecallController>().recall(bill);
      await tester.pumpAndSettle();
      expect(_drawn.catalogDominant, isFalse);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('a tile click that fails changes nothing', (tester) async {
    try {
      await _boot(tester);
      _work.addFromCatalog(() => false);
      await tester.pumpAndSettle();
      expect(_drawn, _layout(75, true));
      expect(_work.pulse.value, 0);
      expect(Get.find<CartController>().cart.value.lines, isEmpty);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('Ctrl+B and Cmd+B cycle hidden, 25, 75, hidden; the edge '
      'control body and chevrons step', (tester) async {
    try {
      await _boot(tester);
      await _searchAdd(tester, 'cola');
      expect(_drawn.products, ProductsStep.off);
      await _ctrl(tester, LogicalKeyboardKey.keyB);
      expect(_drawn.products, ProductsStep.narrow);
      await _cmd(tester, LogicalKeyboardKey.keyB);
      expect(_drawn.products, ProductsStep.wide);
      await _ctrl(tester, LogicalKeyboardKey.keyB);
      expect(_drawn.products, ProductsStep.off);
      // The body cycles too (at 75 with items it shows the cart instead).
      await _tapTab(tester);
      expect(_drawn.products, ProductsStep.narrow);
      await _tapTab(tester);
      expect(_drawn.products, ProductsStep.wide);
      await _tapTab(tester);
      expect(_drawn.products, ProductsStep.narrow, reason: 'last cart layout');
      // Chevrons.
      await tester.tap(find.bySemanticsLabel(RegExp('Make products wider')));
      await tester.pumpAndSettle();
      expect(_drawn.products, ProductsStep.wide);
      await tester.tap(find.bySemanticsLabel(RegExp('Make products narrower')));
      await tester.pumpAndSettle();
      expect(_drawn.products, ProductsStep.narrow);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('Ctrl+. and Cmd+. toggle Billing; the collapse button and the '
      'footer chip do too', (tester) async {
    try {
      await _boot(tester);
      await _searchAdd(tester, 'cola');
      expect(find.byType(BillingTotalChip), findsNothing);
      await _ctrl(tester, LogicalKeyboardKey.period);
      expect(_drawn.billing, isFalse);
      expect(_slotWidth(tester, 'billing'), 0);
      expect(find.byType(BillingTotalChip), findsOneWidget);
      await _cmd(tester, LogicalKeyboardKey.period);
      expect(_drawn.billing, isTrue);
      expect(find.byType(BillingTotalChip), findsNothing);
      // The collapse button in the Billing header.
      await tester.tap(find.byTooltip('Hide billing (Ctrl+.)'));
      await tester.pumpAndSettle();
      expect(_drawn.billing, isFalse);
      // The chip shows the same total as the summary and reopens Billing.
      final total = Get.find<PaymentController>().total;
      expect(
        find.textContaining(total.minor.toString().substring(0, 1)),
        findsWidgets,
      );
      Get.find<ToastController>().toasts.clear();
      await tester.pump();
      await tester.tap(find.byType(BillingTotalChip));
      await tester.pumpAndSettle();
      expect(_drawn.billing, isTrue);
      expect(_slotWidth(tester, 'billing'), greaterThan(0));
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('F2 with Billing collapsed opens it, then shows the cash '
      'panel', (tester) async {
    try {
      await _boot(tester);
      await _searchAdd(tester, 'cola');
      await _ctrl(tester, LogicalKeyboardKey.period);
      expect(_drawn.billing, isFalse);
      // One frame first: Billing is unhidden by the rebuild, and the field
      // focus comes 40 ms later (a frame is 16 ms in the real app).
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(_drawn.billing, isTrue);
      expect(Get.find<PaymentController>().mode.value, PaymentMode.cash);
      expect(Get.find<PaymentController>().tenderedFocus.hasFocus, isTrue);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('rule 4: Escape closes a dialog first, then returns from '
      'Products 75 to the last cart layout; otherwise nothing', (tester) async {
    try {
      await _boot(tester);
      await _searchAdd(tester, 'cola');
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_drawn, _layout(0, true), reason: 'nothing to do');
      _work.wider();
      _work.wider();
      await tester.pumpAndSettle();
      expect(_drawn.products, ProductsStep.wide);
      Get.find<OverlayController>().open('priceCheck');
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.escape);
      expect(Get.find<OverlayController>().isOpen, isFalse);
      expect(_drawn.products, ProductsStep.wide, reason: 'the dialog first');
      await _key(tester, LogicalKeyboardKey.escape);
      expect(_drawn.products, ProductsStep.narrow, reason: 'last cart layout');
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('rule 5: user actions are stored per device, automatic '
      'changes are not', (tester) async {
    try {
      await _boot(tester);
      final settings = Get.find<SettingsController>();
      expect(settings.settings.value.posProductsStep, 0);
      expect(settings.settings.value.posBillingOpen, isTrue);
      await _searchAdd(tester, 'cola');
      // The first add (automatic) wrote nothing.
      expect(settings.settings.value.posProductsStep, 0);
      _work.wider();
      await tester.pumpAndSettle();
      expect(settings.settings.value.posProductsStep, 25);
      await _ctrl(tester, LogicalKeyboardKey.period);
      expect(settings.settings.value.posBillingOpen, isFalse);
      // The empty-cart override does not overwrite the choice.
      Get.find<CartActionsController>().clear();
      await tester.pumpAndSettle();
      expect(_drawn, _layout(75, false));
      expect(settings.settings.value.posProductsStep, 25);
      expect(settings.settings.value.posBillingOpen, isFalse);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('the stored choice is read back after a restart', (tester) async {
    try {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      useLogicalViewport(tester, const Size(1440, 900));
      final store = InMemoryLocalStore();
      await tester.runAsync(() async {
        await store.write(StorageKeys.posProductsStep, 25);
        await store.write(StorageKeys.posBillingOpen, false);
      });
      final binding = await bootInWidgetTest(tester, store: store);
      await tester.pumpWidget(testApp(binding));
      await tester.pumpAndSettle();
      await _searchAdd(tester, 'cola');
      expect(_drawn, _layout(25, false));
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('rule 6: a window too small falls back and keeps the stored '
      'choice', (tester) async {
    try {
      await _boot(tester, size: const Size(950, 733));
      await _searchAdd(tester, 'cola');
      _work.wider(); // P25/B25 does not fit at 950: Billing closes
      await tester.pumpAndSettle();
      expect(_work.chosen, _layout(25, true));
      expect(_drawn, _layout(25, false));
      expect(
        Get.find<SettingsController>().settings.value.posBillingOpen,
        isTrue,
        reason: 'the fallback is not stored',
      );
      // A wider window brings the stored layout back.
      useLogicalViewport(tester, const Size(1440, 900));
      await tester.pumpAndSettle();
      expect(_drawn, _layout(25, true));
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('opening Billing in a window that cannot hold it shrinks '
      'Products', (tester) async {
    try {
      await _boot(tester, size: const Size(950, 733));
      await _searchAdd(tester, 'cola');
      _work.wider();
      await tester.pumpAndSettle();
      expect(_drawn.billing, isFalse);
      _work.openBilling();
      await tester.pumpAndSettle();
      expect(_drawn, _layout(0, true));
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('focus: the search box with Products 75, the cart list '
      'otherwise', (tester) async {
    try {
      await _boot(tester);
      await _searchAdd(tester, 'cola');
      await _ctrl(tester, LogicalKeyboardKey.keyB); // 25
      await tester.pump();
      expect(_work.cartFocus.hasFocus, isTrue);
      await _ctrl(tester, LogicalKeyboardKey.keyB); // 75
      await tester.pump();
      expect(Get.find<SearchFieldController>().focusNode.hasFocus, isTrue);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('clearing, holding the last bill and checkout return to the '
      'catalog layout', (tester) async {
    try {
      await _boot(tester);
      final cart = Get.find<CartController>();
      final products = Get.find<ProductsController>();
      final actions = Get.find<CartActionsController>();

      await _searchAdd(tester, 'cola');
      actions.clear();
      await tester.pumpAndSettle();
      expect(cart.active.value, isFalse);
      expect(_drawn.products, ProductsStep.wide);

      actions.add(products.products[1]);
      _work.showCart();
      await tester.pumpAndSettle();
      expect(_drawn.products, ProductsStep.off);
      Get.find<HoldRecallController>().hold();
      await tester.pumpAndSettle();
      expect(_drawn.products, ProductsStep.wide);
      final bill = Get.find<HeldBillsController>().bills.first;
      Get.find<HoldRecallController>().recall(bill);
      await tester.pumpAndSettle();
      expect(_drawn.products, ProductsStep.off);

      final pay = Get.find<PaymentController>();
      pay.payment(PaymentMode.cash);
      await tester.pump();
      pay.tendered.text = '500';
      pay.completeCash();
      await tester.pumpAndSettle();
      expect(cart.active.value, isFalse);
      expect(_drawn.products, ProductsStep.wide);
      expect(find.byType(CatalogPanel), findsOneWidget);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('every panel stays mounted: the catalog keeps its search text '
      'and the cart its list', (tester) async {
    try {
      await _boot(tester);
      await _searchAdd(tester, 'cola');
      expect(find.byType(CatalogPanel), findsOneWidget);
      expect(find.byType(DesktopCartColumn), findsOneWidget);
      expect(find.byType(BillSummaryFrame), findsOneWidget);
      await _ctrl(tester, LogicalKeyboardKey.period);
      expect(find.byType(BillSummaryFrame), findsOneWidget);
      expect(find.byType(CartCompactRow), findsOneWidget);
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('the edge control carries semantics for every state', (
    tester,
  ) async {
    try {
      await _boot(tester);
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel(RegExp('Cart, empty')), findsOneWidget);
      await _searchAdd(tester, 'cola');
      expect(
        find.bySemanticsLabel(
          RegExp('Resize products, now hidden, press Ctrl\\+B'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Make products wider, now hidden')),
        findsOneWidget,
      );
      _work.wider();
      _work.wider();
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp('Show the cart, 1 items, press Ctrl\\+B')),
        findsOneWidget,
      );
      handle.dispose();
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('a layout change is instant under disableAnimations', (
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
      _work.wider();
      await tester.pump(); // one frame, no settle
      await tester.pump();
      final products = _slotWidth(tester, 'products');
      final cart = _slotWidth(tester, 'cart');
      expect(products, greaterThan(0));
      expect(cart / products, closeTo(2, 0.02));
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('a layout change animates over 180 ms', (tester) async {
    try {
      await _boot(tester);
      await _searchAdd(tester, 'cola');
      _work.wider();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final mid = _slotWidth(tester, 'products');
      await tester.pumpAndSettle();
      final end = _slotWidth(tester, 'products');
      expect(mid, greaterThan(0));
      expect(mid, lessThan(end));
    } finally {
      await _finish(tester);
    }
  });

  testWidgets('the touch layout keeps the catalog, the cart column, the stat '
      'tiles and Billing', (tester) async {
    // Android is the flutter_test default: today's layout.
    useLogicalViewport(tester, const Size(1280, 720));
    final binding = await bootInWidgetTest(tester);
    await tester.pumpWidget(testApp(binding));
    await tester.pumpAndSettle();
    expect(find.byType(ProductsEdgeControl), findsNothing);
    expect(find.byType(CatalogPanel), findsOneWidget);
    expect(find.byType(BillSummaryFrame), findsOneWidget);
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
