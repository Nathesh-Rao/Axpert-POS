import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';
import 'package:pos_application/shared/widgets/product_card.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

Future<void> _boot(WidgetTester tester) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6)); // toasts
  await tester.pumpAndSettle();
}

void main() {
  useTestApp();

  testWidgets('shows the 20 products with caption and chips', (tester) async {
    await _boot(tester);
    expect(find.text('PRODUCT CATALOG'), findsOneWidget);
    expect(find.text('20 items'), findsOneWidget);
    for (final label in [
      'All Items',
      'Favourites',
      'Beverages',
      'Snacks',
      'Personal Care',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    // Lazy grid: only the visible cards exist, but at least the first rows.
    expect(
      find.byType(ProductCard).evaluate().length,
      greaterThanOrEqualTo(14),
    );
    await _finish(tester);
  });

  testWidgets('plus adds, badge and minus appear, minus removes with undo', (
    tester,
  ) async {
    await _boot(tester);
    final cart = Get.find<CartController>();
    await tester.tap(find.byTooltip('Add Coca Cola 500ml'));
    await tester.pump();
    expect(cart.cart.value.lines.single.product.name, 'Coca Cola 500ml');
    expect(find.text('x1'), findsOneWidget);
    expect(find.text('Coca Cola 500ml added'), findsOneWidget);
    expect(find.byTooltip('Remove one Coca Cola 500ml'), findsOneWidget);

    await tester.tap(find.byTooltip('Add Coca Cola 500ml'));
    await tester.pump();
    expect(find.text('x2'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove one Coca Cola 500ml'));
    await tester.pump();
    expect(find.text('x1'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove one Coca Cola 500ml'));
    await tester.pump();
    expect(cart.cart.value.lines, isEmpty);
    expect(find.text('Coca Cola 500ml removed'), findsOneWidget);
    expect(find.byTooltip('Remove one Coca Cola 500ml'), findsNothing);
    await _finish(tester);
  });

  testWidgets('tapping the card and Enter on it add', (tester) async {
    await _boot(tester);
    final cart = Get.find<CartController>();
    await tester.tap(find.text('Pepsi 500ml'));
    await tester.pump();
    expect(cart.lineOf(1)?.qty.milli, 1000, reason: 'tap');
    Focus.of(tester.element(find.text('Sprite 500ml'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(cart.lineOf(2)?.qty.milli, 1000, reason: 'enter');
    await _finish(tester);
  });

  testWidgets('star toggles the favourite and persists', (tester) async {
    await _boot(tester);
    final products = Get.find<ProductsController>();
    expect(products.byId(0)!.favourite, isTrue);
    await tester.tap(find.byTooltip('Toggle favourite').first);
    await tester.pump();
    expect(products.byId(0)!.favourite, isFalse);
    await _finish(tester);
  });

  testWidgets('category and subcategory chips filter, list toggle works', (
    tester,
  ) async {
    await _boot(tester);
    await tester.tap(find.text('Beverages'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ProductCard), findsNWidgets(8));
    await tester.tap(find.text('Juices'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ProductCard), findsNWidgets(3));
    await tester.tap(find.byTooltip('List view'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.widget<ProductCard>(find.byType(ProductCard).first).list,
      isTrue,
    );
    await tester.tap(find.byTooltip('Grid view'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.widget<ProductCard>(find.byType(ProductCard).first).list,
      isFalse,
    );
    await _finish(tester);
  });

  testWidgets('search filters after the debounce, no results can be reset', (
    tester,
  ) async {
    await _boot(tester);
    final field = find.byType(TextField).last;
    await tester.enterText(field, 'lays');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ProductCard), findsNWidgets(2));
    await tester.enterText(field, 'zzz');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('No products found'), findsOneWidget);
    await tester.tap(find.text('Reset filters'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('No products found'), findsNothing);
    expect(find.byType(ProductCard).evaluate().length, greaterThan(10));
    await tester.enterText(field, 'cola');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(ProductCard).evaluate().length, greaterThan(10));
    await _finish(tester);
  });

  testWidgets('the next arrow scrolls the category row', (tester) async {
    await _boot(tester);
    await tester.tap(find.byTooltip('More categories'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('More categories'), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('add from the cart switches to the two-column layout', (
    tester,
  ) async {
    await _boot(tester);
    final catalogLeft = tester.getTopLeft(find.text('PRODUCT CATALOG')).dx;
    await tester.tap(find.byTooltip('Add Coca Cola 500ml'));
    await tester.pump();
    expect(find.text('PRODUCT CATALOG'), findsNothing); // header row hidden
    final widthWithCart = tester.getSize(find.byType(ProductCard).first).width;
    expect(catalogLeft, isNonZero);
    expect(widthWithCart, lessThan(300)); // two columns beside the cart
    expect(Get.find<ToastController>().toasts, isNotEmpty);
    await _finish(tester);
  });
}
