// Bill Summary and checkout flows: totals, cash, card terminal, credit,
// member card, forex. Runs on VM and Chrome.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/modules/customers/controllers/customers_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_meta_controller.dart';
import 'package:pos_application/modules/pos/controllers/member_controller.dart';
import 'package:pos_application/modules/pos/controllers/payment_controller.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/payment_state.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';
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

Future<void> _addLays(WidgetTester tester) async {
  Get.find<CartActionsController>().add(
    Get.find<ProductsController>().byId(5)!,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

Finder _tendered() => find.byWidgetPredicate(
  (w) =>
      w is TextField && w.controller == Get.find<PaymentController>().tendered,
);

void main() {
  useTestApp();

  testWidgets('totals card and forex follow the cart', (tester) async {
    await _boot(tester);
    expect(find.text('₹0.00'), findsWidgets);
    await _addLays(tester);
    expect(find.text('₹20.00'), findsWidgets); // subtotal
    expect(find.text('₹1.00'), findsOneWidget); // tax
    expect(find.text('₹21.00'), findsWidgets); // invoice, amount due
    // 21.00 / 8.561 = 2.4529 -> 2.45 in both conversion boxes.
    expect(find.text('2.45'), findsNWidgets(2));
    expect(find.text('8.561'), findsOneWidget);
    await _drain(tester);
  });

  testWidgets('cash: F2 fills the total, Enter completes the sale', (
    tester,
  ) async {
    await _boot(tester);
    final pay = Get.find<PaymentController>();
    pay.payment(PaymentMode.cash); // empty cart: nothing happens
    expect(pay.tendered.text, '');
    await _addLays(tester);
    expect(pay.canCompleteCash, isFalse);
    expect(find.text('₹-21.00'), findsOneWidget); // change due, short
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump(const Duration(milliseconds: 100));
    expect(pay.tendered.text, '21.00');
    expect(pay.canCompleteCash, isTrue);
    await tester.tap(find.text('500'));
    await tester.pump();
    expect(pay.tendered.text, '500');
    expect(find.text('₹479.00'), findsOneWidget);
    await tester.tap(find.text('Exact'));
    await tester.pump();
    expect(pay.tendered.text, '21');
    await tester.tap(_tendered());
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 100));

    final sales = Get.find<SalesController>().sales;
    expect(sales, hasLength(1));
    expect(sales.single.number, 'AX000001');
    expect(sales.single.mode, 'Cash');
    expect(sales.single.change, Money(0, sales.single.change.currency));
    expect(Get.find<CartController>().isActive, isFalse);
    expect(Get.find<ProductsController>().byId(5)!.stock, 45 + 5 * 3 - 1);
    expect(Get.find<OverlayController>().modal.value, 'receipt');
    expect(Get.find<OverlayController>().payload, sales.single);
    expect(Get.find<ToastController>().toasts.last.text, 'Payment completed');
    await _drain(tester);
  });

  testWidgets('tendered below the total cannot complete', (tester) async {
    await _boot(tester);
    await _addLays(tester);
    final pay = Get.find<PaymentController>();
    pay.tendered.text = '20.99';
    await tester.pump();
    expect(pay.canCompleteCash, isFalse);
    pay.tendered.text = '21';
    await tester.pump();
    expect(pay.canCompleteCash, isTrue);
    await _drain(tester);
  });

  testWidgets('card: waiting 2 s, approved, complete; decline and retry', (
    tester,
  ) async {
    await _boot(tester);
    await _addLays(tester);
    final pay = Get.find<PaymentController>();
    await tester.sendKeyEvent(LogicalKeyboardKey.f3);
    await tester.pump(const Duration(milliseconds: 100));
    expect(pay.mode.value, PaymentMode.card);
    expect(find.text('Waiting for card...'), findsOneWidget);
    expect(pay.canCompleteCard, isFalse);
    await tester.pump(const Duration(milliseconds: 1950));
    expect(find.text('Approved'), findsOneWidget);
    expect(pay.canCompleteCard, isTrue);

    // Decline while waiting is applied when the timer fires.
    pay.retry();
    pay.setDecline(true);
    await tester.pump(const Duration(milliseconds: 2100));
    expect(find.text('Card declined'), findsOneWidget);
    expect(pay.canCompleteCard, isFalse);
    pay.retry();
    expect(pay.decline.value, isFalse);
    await tester.pump(const Duration(milliseconds: 2100));
    expect(find.text('Approved'), findsOneWidget);

    pay.completeCard();
    await tester.pump(const Duration(milliseconds: 100));
    final sale = Get.find<SalesController>().sales.single;
    expect(sale.mode, 'Card');
    expect(sale.tendered, sale.totals.total);
    // The cart emptied: payment panel resets to cash.
    expect(pay.mode.value, PaymentMode.cash);
    await _drain(tester);
  });

  testWidgets('credit needs a customer, confirms, saves without payment', (
    tester,
  ) async {
    await _boot(tester);
    await _addLays(tester);
    final pay = Get.find<PaymentController>();
    final meta = Get.find<CartMetaController>();
    meta.setSaleType(SaleType.credit);
    await tester.pump();
    expect(find.text('Select a customer to save a credit sale.'), findsOne);
    expect(pay.canPay, isFalse);
    expect(find.text('Save Credit'), findsOneWidget);
    pay.payment(PaymentMode.cash);
    expect(Get.find<OverlayController>().isOpen, isFalse);

    meta.setCustomer('1');
    await tester.pump();
    expect(pay.canPay, isTrue);
    pay.payment(PaymentMode.cash);
    await tester.pumpAndSettle();
    expect(find.text('Save ₹21.00 on credit for Ananya Sharma?'), findsOne);
    await tester.tap(find.text('Confirm'));
    await tester.pump(const Duration(milliseconds: 100));
    final sale = Get.find<SalesController>().sales.single;
    expect(sale.mode, 'Credit');
    expect(sale.customer, 'Ananya Sharma');
    expect(sale.tendered, Money(0, sale.tendered.currency));
    expect(Get.find<ToastController>().toasts.last.text, 'Saved on credit');
    await _drain(tester);
  });

  testWidgets('member number selects the customer; points clamp', (
    tester,
  ) async {
    await _boot(tester);
    await _addLays(tester);
    final member = Get.find<MemberController>();
    final cart = Get.find<CartController>();
    member.memberText.text = 'mg1001';
    member.lookup('mg1001');
    await tester.pump();
    expect(cart.cart.value.customer, '1');
    expect(member.memberText.text, 'MG1001');
    expect(
      Get.find<ToastController>().toasts.last.text,
      'Welcome, Ananya Sharma',
    );
    member.setPoints('999');
    expect(cart.cart.value.points, 250);
    member.setPoints('7.9');
    expect(cart.cart.value.points, 7);
    member.setPoints('-3');
    expect(cart.cart.value.points, 0);
    member.setPoints('10');
    expect(
      cart.totals.value.points,
      Money(1000, cart.totals.value.total.currency),
    );
    // Changing the customer resets the points.
    Get.find<CartMetaController>().selectCustomer('2');
    expect(cart.cart.value.points, 0);
    expect(Get.find<CustomersController>().customers, hasLength(4));
    await _drain(tester);
  });

  testWidgets('unknown member number: Enter warns', (tester) async {
    await _boot(tester);
    final member = Get.find<MemberController>();
    member.memberText.text = 'MG9';
    member.submit();
    expect(
      Get.find<ToastController>().toasts.last.text,
      'Member not found. Try MG1001, MG1002 or MG1003',
    );
    await _drain(tester);
  });

  testWidgets('sale toggle, buttons disabled while empty', (tester) async {
    await _boot(tester);
    final pay = Get.find<PaymentController>();
    expect(pay.canPay, isFalse);
    await tester.tap(find.text('Credit Sale').first);
    await tester.pump();
    expect(Get.find<CartController>().cart.value.saleType, SaleType.credit);
    await tester.tap(find.text('Cash Sale').first);
    await tester.pump();
    expect(Get.find<CartController>().cart.value.saleType, SaleType.cash);
    await _drain(tester);
  });
}
