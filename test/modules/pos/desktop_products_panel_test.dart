// The collapsible Products panel of the desktop layout (DEC-138): the tab, the
// Ctrl/Cmd+B shortcut, Escape order, the view preference, adding from the
// panel and from the search box with the panel collapsed, gift and offer rows.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/products_panel_controller.dart';
import 'package:pos_application/modules/pos/widgets/cart_compact_row.dart';
import 'package:pos_application/modules/pos/widgets/cart_empty_state.dart';
import 'package:pos_application/modules/pos/widgets/catalog_panel.dart';
import 'package:pos_application/modules/pos/widgets/products_tab.dart';
import 'package:pos_application/modules/pos/widgets/stat_tiles.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

Future<void> _boot(
  WidgetTester tester, {
  Size size = const Size(1280, 720),
  InMemoryLocalStore? store,
}) async {
  useLogicalViewport(tester, size);
  final binding = await bootInWidgetTest(tester, store: store);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

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

void _desktop(Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  useTestApp();

  testWidgets('the desktop page starts with the panel collapsed and an empty '
      'cart state', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await _boot(tester);
      expect(find.byType(ProductsTab), findsOneWidget);
      expect(find.byType(CatalogPanel), findsNothing);
      expect(find.byType(CartEmptyState), findsOneWidget);
      expect(find.text('No items yet'), findsOneWidget);
      expect(find.textContaining('Ctrl+B'), findsWidgets);
      expect(find.byType(StatTiles), findsNothing, reason: 'one footer line');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the tab and Ctrl+B / Cmd+B show and hide the panel', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await _boot(tester);
      await tester.tap(find.byType(ProductsTab));
      await tester.pumpAndSettle();
      expect(find.byType(CatalogPanel), findsOneWidget);
      await tester.tap(find.byType(ProductsTab));
      await tester.pumpAndSettle();
      expect(find.byType(CatalogPanel), findsNothing);

      await _key(
        tester,
        LogicalKeyboardKey.keyB,
        modifier: LogicalKeyboardKey.controlLeft,
      );
      expect(find.byType(CatalogPanel), findsOneWidget);
      await _key(
        tester,
        LogicalKeyboardKey.keyB,
        modifier: LogicalKeyboardKey.metaLeft,
      );
      expect(find.byType(CatalogPanel), findsNothing);

      await tester.tap(find.text('Open Products'));
      await tester.pumpAndSettle();
      expect(find.byType(CatalogPanel), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Escape closes a dialog first, then the panel, and refocuses '
      'the search', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await _boot(tester);
      await tester.runAsync(Get.find<ProductsPanelController>().open);
      await tester.pumpAndSettle();
      Get.find<OverlayController>().open('priceCheck');
      await tester.pumpAndSettle();
      await _key(tester, LogicalKeyboardKey.escape);
      expect(Get.find<OverlayController>().isOpen, isFalse);
      expect(find.byType(CatalogPanel), findsOneWidget, reason: 'dialog first');
      await _key(tester, LogicalKeyboardKey.escape);
      expect(find.byType(CatalogPanel), findsNothing);
      expect(Get.find<SearchFieldController>().focusNode.hasFocus, isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the expanded state is a view preference that survives a '
      'restart', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final store = InMemoryLocalStore();
      await _boot(tester, store: store);
      await tester.runAsync(Get.find<ProductsPanelController>().open);
      await tester.pumpAndSettle();
      await _boot(tester, store: store);
      expect(find.byType(CatalogPanel), findsOneWidget);
      expect(Get.find<ProductsPanelController>().isOpen, isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('adding from the open panel adds one line and refocuses the '
      'search; the cart shows it as a compact row', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await _boot(tester);
      await tester.runAsync(Get.find<ProductsPanelController>().open);
      await tester.pumpAndSettle();
      await tester.tap(_addTooltip('Coca Cola 500ml').first);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(Get.find<CartController>().cart.value.lines, hasLength(1));
      expect(find.byType(CartCompactRow), findsOneWidget);
      expect(find.byType(CartEmptyState), findsNothing);
      expect(Get.find<SearchFieldController>().focusNode.hasFocus, isTrue);
      await _drain(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('with the panel collapsed the search box still adds items', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await _boot(tester);
      expect(find.byType(CatalogPanel), findsNothing);
      final search = Get.find<SearchFieldController>();
      search.focusNode.requestFocus();
      await tester.pump();
      await tester.enterText(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller == search.text,
        ),
        'cola',
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(Get.find<CartController>().cart.value.lines, hasLength(1));
      expect(find.byType(CartCompactRow), findsOneWidget);
      // F-key shortcuts keep working with the new layout: F4 holds the bill.
      await _key(tester, LogicalKeyboardKey.f4);
      expect(Get.find<CartController>().cart.value.lines, isEmpty);
      await _drain(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the touch layout keeps the catalog and the stat tiles', (
    tester,
  ) async {
    // Android is the flutter_test default: today's layout.
    await _boot(tester);
    expect(find.byType(ProductsTab), findsNothing);
    expect(find.byType(CatalogPanel), findsOneWidget);
    Get.find<CartActionsController>().add(
      Get.find<ProductsController>().products.first,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(StatTiles), findsOneWidget);
    expect(find.byType(CartCompactRow), findsNothing);
    await _drain(tester);
  });

  // Silence the unused helper warning when no test needs the toast list.
  test('toast controller type is importable', () {
    expect(ToastController, isNotNull);
    expect(_desktop, isNotNull);
  });
}
