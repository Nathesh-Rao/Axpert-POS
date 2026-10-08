import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_selection_controller.dart';
import 'package:pos_application/modules/pos/widgets/cart_line_row.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';
import 'package:pos_application/shared/widgets/number_field.dart';
import 'package:pos_application/shared/widgets/quantity_field.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

Future<void> _boot(WidgetTester tester, {List<int> add = const <int>[]}) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  final products = Get.find<ProductsController>();
  for (final id in add) {
    Get.find<CartActionsController>().add(products.byId(id)!);
  }
  await tester.pump();
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

Finder _field<T extends Widget>(int index) => find.descendant(
  of: find.byType(T).at(index),
  matching: find.byType(TextField),
);

Future<void> _done(WidgetTester tester) async {
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

void main() {
  useTestApp();

  testWidgets('first add shows the cart: row, head, tiles, actions', (
    tester,
  ) async {
    await _boot(tester, add: const <int>[5]);
    expect(find.byType(CartLineRow), findsOneWidget);
    expect(find.text('C3'), findsOneWidget);
    for (final label in ['Item', 'Qty', 'Price', 'Disc %', 'Total']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Lays Classic 52g'), findsWidgets);
    expect(find.text('8901234567895'), findsOneWidget);
    expect(find.text('GST 5%'), findsOneWidget);
    expect(find.text('1.000'), findsWidgets); // qty field and total qty
    expect(find.text('₹20.00'), findsWidgets);
    expect(find.text('Total Items'), findsOneWidget);
    expect(find.text('Total Qty'), findsOneWidget);
    expect(find.text('Total Value'), findsOneWidget);
    for (final label in ['Clear Cart', 'Hold', 'Recall', 'Price Check']) {
      expect(find.text(label), findsOneWidget);
    }
    await _finish(tester);
  });

  testWidgets('stat tiles follow the cart (lakh grouping for value)', (
    tester,
  ) async {
    await _boot(tester, add: const <int>[1, 1, 2]);
    final cart = Get.find<CartController>();
    expect(cart.totals.value.items, 2);
    expect(find.text('3.000'), findsOneWidget); // total qty
    expect(find.text('120.00'), findsOneWidget); // total value
    await tester.enterText(_field<NumberField>(0), '123456');
    await tester.pump();
    expect(find.text('2,46,952.00'), findsOneWidget); // 2 x 123456 + 40
    await _finish(tester);
  });

  testWidgets('quantity field: commit while typing, stock, zero removes', (
    tester,
  ) async {
    await _boot(tester, add: const <int>[5]);
    final cart = Get.find<CartController>();
    final field = _field<QuantityField>(0);
    await tester.enterText(field, '3');
    await tester.pump();
    expect(cart.lineOf(5)!.qty, Qty.units(3));
    await tester.enterText(field, '2.5');
    await tester.pump();
    expect(cart.lineOf(5)!.qty, const Qty(2500));
    // Over stock (60): toast, cart unchanged.
    await tester.enterText(field, '99');
    await tester.pump();
    expect(find.text('Only 60 available in stock'), findsOneWidget);
    expect(cart.lineOf(5)!.qty, const Qty(2500));
    // Leaving the field shows the current value again.
    await _done(tester);
    expect(find.text('2.500'), findsWidgets);
    // 0 on leaving the field removes the line.
    await tester.enterText(field, '0');
    await _done(tester);
    expect(cart.lineOf(5), isNull);
    expect(find.text('Lays Classic 52g removed'), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('price: min 0; discount: clamped 0-100 and the text snaps', (
    tester,
  ) async {
    await _boot(tester, add: const <int>[5]);
    final cart = Get.find<CartController>();
    final price = _field<NumberField>(0);
    final discount = _field<NumberField>(1);
    await tester.enterText(price, '25.5');
    await tester.pump();
    expect(cart.lineOf(5)!.price.minor, 2550);
    expect(tester.widget<TextField>(price).controller!.text, '25.5');
    await tester.enterText(price, '-3');
    await tester.pump();
    expect(cart.lineOf(5)!.price.minor, 0);
    expect(tester.widget<TextField>(price).controller!.text, '0');
    await tester.enterText(discount, '150');
    await tester.pump();
    expect(cart.lineOf(5)!.discount.value, 10000);
    expect(tester.widget<TextField>(discount).controller!.text, '100');
    await tester.enterText(discount, '12.5');
    await tester.pump();
    expect(cart.lineOf(5)!.discount.value, 1250);
    await _finish(tester);
  });

  testWidgets('plus and minus buttons, minus at 1 removes the line', (
    tester,
  ) async {
    await _boot(tester, add: const <int>[1]);
    final cart = Get.find<CartController>();
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pump();
    expect(cart.lineOf(1)!.qty, Qty.units(2));
    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pump();
    expect(cart.lineOf(1)!.qty, Qty.units(1));
    await tester.tap(find.byTooltip('Decrease quantity'));
    await tester.pump();
    expect(cart.lineOf(1), isNull);
    await _finish(tester);
  });

  testWidgets('trash removes with a 5 s Undo that restores the line', (
    tester,
  ) async {
    await _boot(tester, add: const <int>[1, 2]);
    final cart = Get.find<CartController>();
    await tester.tap(find.byTooltip('Remove item').first);
    await tester.pump();
    expect(cart.cart.value.lines.map((l) => l.product.id), [2]);
    expect(find.text('Pepsi 500ml removed'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(cart.cart.value.lines.map((l) => l.product.id), [2, 1]);
    // After 5 s the Undo is gone.
    await tester.tap(find.byTooltip('Remove item').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Undo'), findsNothing);
    await _finish(tester);
  });

  testWidgets('Clear Cart asks first; Cancel keeps, Confirm clears', (
    tester,
  ) async {
    await _boot(tester, add: const <int>[1, 2]);
    final cart = Get.find<CartController>();
    await tester.tap(find.text('Clear Cart'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm action'), findsOneWidget);
    expect(find.text('Clear all items and start a new sale?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(cart.cart.value.lines.length, 2);
    await tester.tap(find.text('Clear Cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(cart.cart.value.lines, isEmpty);
    expect(find.byType(CartLineRow), findsNothing);
    await _finish(tester);
  });

  testWidgets('tapping a row selects it; Delete removes the selected line', (
    tester,
  ) async {
    await _boot(tester, add: const <int>[1, 2]);
    final cart = Get.find<CartController>();
    final selection = Get.find<CartSelectionController>();
    expect(selection.selected.value, 2); // the last add selects
    await tester.tap(find.byType(CartLineRow).first, warnIfMissed: false);
    await tester.pump();
    expect(selection.selected.value, 1);
    // Focus is not in a text input: Delete removes the selected line.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(cart.cart.value.lines.map((l) => l.product.id), [2]);
    await _finish(tester);
  });

  testWidgets('catalog adds also scroll and highlight the new line', (
    tester,
  ) async {
    await _boot(tester, add: const <int>[1, 2, 3, 4, 5, 6, 7, 8, 9]);
    final selection = Get.find<CartSelectionController>();
    expect(selection.highlight.value, 9);
    await tester.pump(const Duration(milliseconds: 1700));
    expect(selection.highlight.value, isNull);
    expect(
      Get.find<ToastController>().toasts.length,
      ToastController.maxVisible,
    );
    await _finish(tester);
  });
}
