// Hold (F4), recall (F5) and the bill discount drawer (F6) end to end.
// Runs on VM and Chrome.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/pricing_models.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/discount_form_controller.dart';
import 'package:pos_application/modules/pos/controllers/held_bills_controller.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

Future<void> _boot(WidgetTester tester) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
}

Future<void> _add(WidgetTester tester, int productId) async {
  Get.find<CartActionsController>().add(
    Get.find<ProductsController>().byId(productId)!,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

List<String> _toasts() =>
    Get.find<ToastController>().toasts.map((t) => t.text).toList();

Money _inr(int minor) => Money(minor, CurrencyRegistry.inr);

void main() {
  useTestApp();

  testWidgets('F4 on an empty cart only shows the info toast', (tester) async {
    await _boot(tester);
    await _key(tester, LogicalKeyboardKey.f4);
    expect(_toasts(), <String>['Add items before holding a bill']);
    expect(Get.find<HeldBillsController>().count, 0);
    await _drain(tester);
  });

  testWidgets('F4 holds the cart, F5 lists it, a click recalls it', (
    tester,
  ) async {
    await _boot(tester);
    await _add(tester, 5); // Lays Classic 52g, 20.00
    Get.find<ToastController>().toasts.clear();
    await _key(tester, LogicalKeyboardKey.f4);
    final held = Get.find<HeldBillsController>();
    expect(held.count, 1);
    expect(held.bills.single.ref, matches(RegExp(r'^H\d{1,6}$')));
    expect(Get.find<CartController>().active.value, isFalse);
    expect(_toasts(), <String>['Bill held. Ready for a new sale.']);
    expect(find.text('1'), findsWidgets); // the badge on Recall

    await _key(tester, LogicalKeyboardKey.f5);
    expect(Get.find<OverlayController>().modal.value, 'recall');
    expect(find.text('Held bills'), findsOneWidget);
    expect(find.text('Pick up right where you left off.'), findsOneWidget);
    final ref = held.bills.single.ref;
    expect(find.text('$ref · 1 items'), findsOneWidget);
    expect(find.text('₹21.00'), findsWidgets); // the bill total

    Get.find<ToastController>().toasts.clear();
    await tester.tap(find.text('$ref · 1 items'));
    await tester.pumpAndSettle();
    expect(held.count, 0);
    expect(Get.find<CartController>().cart.value.lines.single.product.id, 5);
    expect(Get.find<OverlayController>().isOpen, isFalse);
    expect(_toasts(), <String>['Bill $ref recalled']);
    await _drain(tester);
  });

  testWidgets('recall with no held bills shows the empty state', (
    tester,
  ) async {
    await _boot(tester);
    await _key(tester, LogicalKeyboardKey.f5);
    expect(find.text('No held bills yet.'), findsOneWidget);
    await _drain(tester);
  });

  testWidgets('recall over an active cart asks: replace or hold and recall', (
    tester,
  ) async {
    await _boot(tester);
    final held = Get.find<HeldBillsController>();
    final cart = Get.find<CartController>();
    await _add(tester, 5);
    await _key(tester, LogicalKeyboardKey.f4);
    final ref = held.bills.single.ref;
    await _add(tester, 1); // Coca Cola in the active cart

    await _key(tester, LogicalKeyboardKey.f5);
    await tester.tap(find.text('$ref · 1 items'));
    await tester.pumpAndSettle();
    expect(find.text('You have an active cart'), findsOneWidget);
    expect(
      find.text('Hold your current cart, or replace it with $ref?'),
      findsOneWidget,
    );
    expect(held.count, 1, reason: 'nothing happens before a choice');

    // Replace current: the Coca Cola cart is dropped.
    await tester.tap(find.text('Replace current'));
    await tester.pumpAndSettle();
    expect(cart.cart.value.lines.map((l) => l.product.id), <int>[5]);
    expect(held.count, 0);

    // Hold & recall: the current cart (Lays) goes to the held list.
    await _add(tester, 1);
    await _key(tester, LogicalKeyboardKey.f4); // hold Lays + Coca
    final second = held.bills.single.ref;
    await _add(tester, 2); // Pepsi
    await _key(tester, LogicalKeyboardKey.f5);
    await tester.tap(find.text('$second · 2 items'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hold & recall'));
    await tester.pumpAndSettle();
    expect(cart.cart.value.lines.length, 2);
    expect(held.count, 1);
    expect(held.bills.single.cart.lines.single.product.id, 2);
    expect(Get.find<OverlayController>().isOpen, isFalse);
    await _drain(tester);
  });

  testWidgets('closing the recall dialog drops a pending question', (
    tester,
  ) async {
    await _boot(tester);
    await _add(tester, 5);
    await _key(tester, LogicalKeyboardKey.f4);
    await _add(tester, 1);
    await _key(tester, LogicalKeyboardKey.f5);
    final ref = Get.find<HeldBillsController>().bills.single.ref;
    await tester.tap(find.text('$ref · 1 items'));
    await tester.pumpAndSettle();
    Get.find<OverlayController>().close();
    await tester.pumpAndSettle();
    await _key(tester, LogicalKeyboardKey.f5);
    expect(find.text('Held bills'), findsOneWidget);
    await _drain(tester);
  });

  testWidgets('F6 opens the drawer; flat discount applies and is removed', (
    tester,
  ) async {
    await _boot(tester);
    final cart = Get.find<CartController>();
    final form = Get.find<DiscountFormController>();
    await _add(tester, 5); // 20.00 + 5 % tax
    Finder valueField() => find.byWidgetPredicate(
      (w) => w is TextField && w.controller == form.value,
    );
    Finder reasonField() => find.byWidgetPredicate(
      (w) => w is TextField && w.controller == form.reason,
    );

    await _key(tester, LogicalKeyboardKey.f6);
    expect(Get.find<OverlayController>().modal.value, 'discount');
    expect(find.text('Bill discount'), findsOneWidget);
    expect(find.text('Apply a discount to this entire bill.'), findsOneWidget);
    expect(form.value.text, '0');

    // Percent is clamped to 100 while typing.
    await tester.enterText(valueField(), '150');
    await tester.pump();
    expect(form.value.text, '100');

    await tester.tap(find.text('Flat amount ₹'));
    await tester.pump();
    await tester.enterText(valueField(), '5');
    await tester.enterText(reasonField(), 'Seasonal offer');
    await tester.tap(find.text('Apply discount'));
    await tester.pumpAndSettle();
    expect(Get.find<OverlayController>().isOpen, isFalse);
    expect(cart.cart.value.billDiscount.type, BillDiscountType.flat);
    expect(cart.cart.value.billDiscount.flat, _inr(500));
    expect(cart.cart.value.reason, 'Seasonal offer');
    expect(cart.totals.value.discount, _inr(500));

    // Reopened: the form shows the stored discount.
    await _key(tester, LogicalKeyboardKey.f6);
    expect(form.type.value, BillDiscountType.flat);
    expect(form.value.text, '5');
    expect(form.reason.text, 'Seasonal offer');

    // A flat amount is clamped to the subtotal.
    await tester.enterText(valueField(), '99');
    await tester.pump();
    expect(form.value.text, '20');

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(cart.cart.value.billDiscount.flat, isNull);
    expect(cart.cart.value.reason, '');
    expect(cart.totals.value.discount.isZero, isTrue);
    await _drain(tester);
  });

  testWidgets('percent discount applies to the bill', (tester) async {
    await _boot(tester);
    final cart = Get.find<CartController>();
    final form = Get.find<DiscountFormController>();
    await _add(tester, 5);
    await _key(tester, LogicalKeyboardKey.f6);
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.controller == form.value,
      ),
      '10',
    );
    await tester.tap(find.text('Apply discount'));
    await tester.pumpAndSettle();
    expect(cart.totals.value.discount, _inr(200));
    await _drain(tester);
  });
}
