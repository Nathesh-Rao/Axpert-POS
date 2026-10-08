// Top-bar search, scan simulator, price check, customer picker and add
// customer end to end. Runs on VM and Chrome.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/modules/customers/controllers/add_customer_controller.dart';
import 'package:pos_application/modules/customers/controllers/customer_picker_controller.dart';
import 'package:pos_application/modules/customers/controllers/customers_controller.dart';
import 'package:pos_application/modules/customers/widgets/customer_picker_dialog.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/global_search_controller.dart';
import 'package:pos_application/modules/pos/controllers/member_controller.dart';
import 'package:pos_application/modules/pos/controllers/price_check_controller.dart';
import 'package:pos_application/modules/pos/controllers/scan_controller.dart';
import 'package:pos_application/modules/pos/widgets/dialogs/price_check_dialog.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

Future<void> _boot(WidgetTester tester) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

Finder _field(TextEditingController controller) =>
    find.byWidgetPredicate((w) => w is TextField && w.controller == controller);

Future<void> _type(WidgetTester tester, String text) async {
  final search = Get.find<SearchFieldController>();
  search.focusNode.requestFocus();
  await tester.pump();
  await tester.enterText(_field(search.text), text);
  // The dropdown is debounced (120 ms).
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump();
}

List<String> _toasts() =>
    Get.find<ToastController>().toasts.map((t) => t.text).toList();

List<int> _cartIds() => Get.find<CartController>().cart.value.lines
    .map((l) => l.product.id)
    .toList();

void main() {
  useTestApp();

  testWidgets('typing shows up to 6 matches; Enter adds the first', (
    tester,
  ) async {
    await _boot(tester);
    await _type(tester, 'cola');
    expect(find.text('Coca Cola 500ml'), findsWidgets);
    expect(find.text('BDV001'), findsWidgets);
    expect(Get.find<GlobalSearchController>().matches.length, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_cartIds(), <int>[0]);
    expect(Get.find<SearchFieldController>().text.text, '');
    expect(Get.find<GlobalSearchController>().matches, isEmpty);
    await _drain(tester);
  });

  testWidgets('arrows move the highlight and Enter picks it; wraps', (
    tester,
  ) async {
    await _boot(tester);
    await _type(tester, 'bdv00');
    final search = Get.find<GlobalSearchController>();
    expect(search.matches.length, 4);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(search.highlight.value, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(search.highlight.value, 3, reason: 'wraps to the last row');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_cartIds(), <int>[1], reason: 'second product, Pepsi');
    await _drain(tester);
  });

  testWidgets('a click on a result adds the product', (tester) async {
    await _boot(tester);
    await _type(tester, 'pepsi');
    await tester.tap(find.text('Pepsi 500ml').first);
    await tester.pumpAndSettle();
    expect(_cartIds(), <int>[1]);
    await _drain(tester);
  });

  testWidgets('digits never open the dropdown; Enter scans the barcode', (
    tester,
  ) async {
    await _boot(tester);
    await _type(tester, '8901234567893'); // Fanta
    expect(Get.find<GlobalSearchController>().matches, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_cartIds(), <int>[3]);
    await _drain(tester);
  });

  testWidgets('a miss shows the error toast and clears the field', (
    tester,
  ) async {
    await _boot(tester);
    await _type(tester, '000');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(_toasts(), <String>['Product not found for barcode 000']);
    expect(Get.find<SearchFieldController>().text.text, '');
    expect(_cartIds(), isEmpty);
    await _drain(tester);
  });

  testWidgets('the scan dialog: Enter scans, Simulate needs text', (
    tester,
  ) async {
    await _boot(tester);
    final scan = Get.find<ScanController>();
    Get.find<OverlayController>().open('scan');
    await tester.pumpAndSettle();
    expect(find.text('Scan simulator'), findsWidgets);
    expect(scan.focus.hasFocus, isTrue, reason: 'autofocus');
    expect(scan.hasText.value, isFalse);
    await tester.tap(find.text('Simulate scan'));
    await tester.pumpAndSettle();
    expect(Get.find<OverlayController>().isOpen, isTrue, reason: 'disabled');

    await tester.enterText(_field(scan.text), ' 8901234567890 ');
    await tester.pump();
    expect(scan.hasText.value, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(_cartIds(), <int>[0], reason: 'the barcode is trimmed');
    expect(Get.find<OverlayController>().isOpen, isFalse);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      Get.find<SearchFieldController>().focusNode.hasFocus,
      isTrue,
      reason: 'focus returns to the search field',
    );
    await _drain(tester);
  });

  testWidgets('scan random adds a product with stock', (tester) async {
    await _boot(tester);
    Get.find<OverlayController>().open('scan');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan random product'));
    await tester.pumpAndSettle();
    expect(_cartIds().length, 1);
    expect(Get.find<OverlayController>().isOpen, isFalse);
    await _drain(tester);
  });

  testWidgets('scan random chooses with the injected Random', (tester) async {
    await _boot(tester);
    final scan = Get.find<ScanController>();
    final again = ScanController(
      products: scan.products,
      actions: scan.actions,
      toasts: scan.toasts,
      search: scan.search,
      overlay: scan.overlay,
      random: Random(0),
    );
    again.scanRandom();
    final first = _cartIds().single;
    expect(first, inInclusiveRange(0, 19));
    await _drain(tester);
  });

  testWidgets('price check: lookup per keystroke, not trimmed, no add', (
    tester,
  ) async {
    await _boot(tester);
    final check = Get.find<PriceCheckController>();
    Get.find<OverlayController>().open('priceCheck');
    await tester.pumpAndSettle();
    expect(find.text('Price Check'), findsWidgets);
    expect(check.focus.hasFocus, isTrue);

    await tester.enterText(_field(check.text), 'bdv001');
    await tester.pump();
    Finder inDialog(String t) => find.descendant(
      of: find.byType(PriceCheckDialog),
      matching: find.text(t),
    );
    expect(inDialog('Coca Cola 500ml'), findsOneWidget);
    expect(inDialog('₹40.00'), findsOneWidget);
    expect(inDialog('BDV001 · 45 in stock · GST 18%'), findsOneWidget);

    await tester.enterText(_field(check.text), ' bdv001');
    await tester.pump();
    expect(inDialog('Coca Cola 500ml'), findsNothing);
    expect(inDialog('No matching product. Try BDV001.'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(_toasts(), <String>['Product not found']);
    expect(_cartIds(), isEmpty);

    // Reopening resets the text and the result.
    Get.find<OverlayController>().close();
    await tester.pumpAndSettle();
    Get.find<OverlayController>().open('priceCheck');
    await tester.pumpAndSettle();
    expect(check.text.text, '');
    expect(check.product.value, isNull);
    await _drain(tester);
  });

  testWidgets('customer picker: search, arrows, select, kept text', (
    tester,
  ) async {
    await _boot(tester);
    final picker = Get.find<CustomerPickerController>();
    final cart = Get.find<CartController>();
    Get.find<OverlayController>().open('customers');
    await tester.pumpAndSettle();
    expect(find.text('Find a customer'), findsOneWidget);
    expect(find.text('Walk-in Customer'), findsWidgets);
    expect(find.text('Ananya Sharma'), findsOneWidget);
    expect(find.text('9876543210 MG1001 · 250 points'), findsOneWidget);
    expect(picker.searchFocus.hasFocus, isTrue);

    await tester.enterText(_field(picker.search), 'MG100');
    await tester.pump(const Duration(milliseconds: 250));
    expect(picker.filtered.length, 3);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(picker.highlight.value, 1);
    // Points were set for the old customer: choosing resets them.
    cart.patch((c) => c.copyWith(points: 5));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final chosen = Get.find<CustomersController>().customers.firstWhere(
      (c) => c.name == 'Rahul Mehta',
    );
    expect(cart.cart.value.customer, chosen.id);
    expect(cart.cart.value.points, 0);
    expect(Get.find<MemberController>().memberText.text, 'MG1002');
    expect(Get.find<OverlayController>().isOpen, isFalse);

    // The search text is kept between openings.
    Get.find<OverlayController>().open('customers');
    await tester.pumpAndSettle();
    expect(picker.search.text, 'MG100');
    await _drain(tester);
  });

  testWidgets('add customer: validation, save, selection, kept form', (
    tester,
  ) async {
    await _boot(tester);
    final add = Get.find<AddCustomerController>();
    final customers = Get.find<CustomersController>();
    Get.find<OverlayController>().open('customers');
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(CustomerPickerDialog),
        matching: find.text('Add Customer'),
      ),
    );
    await tester.pumpAndSettle();
    expect(Get.find<OverlayController>().modal.value, 'addCustomer');
    expect(find.text('A little personal service goes a long way.'), findsOne);
    final before = customers.customers.length;

    await tester.enterText(_field(add.name), 'Ravi');
    await tester.enterText(_field(add.phone), '12345');
    await tester.tap(find.text('Save customer'));
    await tester.pump();
    expect(_toasts(), <String>['Enter a name, valid phone and email']);
    expect(customers.customers.length, before);
    expect(add.name.text, 'Ravi', reason: 'the form is kept');
    Get.find<ToastController>().toasts.clear();

    await tester.enterText(_field(add.phone), '98450 11111');
    await tester.enterText(_field(add.email), 'ravi@x.in');
    await tester.tap(find.text('Save customer'));
    await tester.pumpAndSettle();
    expect(customers.customers.length, before + 1);
    final saved = customers.customers.last;
    expect(saved.name, 'Ravi');
    expect(saved.member, matches(RegExp(r'^MG\d{5}$')));
    expect(saved.points, 0);
    expect(Get.find<CartController>().cart.value.customer, saved.id);
    expect(add.name.text, '');
    expect(add.phone.text, '');
    expect(add.email.text, '');
    expect(_toasts(), <String>['Customer added']);
    expect(Get.find<OverlayController>().isOpen, isFalse);
    await _drain(tester);
  });
}
