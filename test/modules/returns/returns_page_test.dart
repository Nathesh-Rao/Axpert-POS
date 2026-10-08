// The Returns page: lookup, checks, confirm, refund effects. VM tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/modules/returns/controllers/returns_controller.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';
import 'package:pos_application/modules/sales/models/sale.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/sale_fixtures.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

Money _inr(int minor) => Money(minor, CurrencyRegistry.inr);

/// 2 x product 1 and 1.5 x product 2 at 40.00 / 20.00: value 110.00, total
/// 129.80.
Sale _sale() {
  final products = Get.find<ProductsController>();
  return testSale(
    number: 'AX000007',
    at: DateTime(2026, 10, 8),
    customer: 'Ananya Sharma',
    totalMinor: 12980,
    valueMinor: 11000,
    cart: Cart(
      lines: <CartLine>[
        CartLine(
          product: products.byId(0)!,
          qty: const Qty(2000),
          price: _inr(4000),
          discount: Bp.zero,
        ),
        CartLine(
          product: products.byId(1)!,
          qty: const Qty(1500),
          price: _inr(2000),
          discount: Bp.zero,
        ),
      ],
    ),
  );
}

Future<ReturnsController> _open(WidgetTester tester) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  Get.find<SalesController>().sales.add(_sale());
  Get.offAllNamed<void>(AppRoutes.returns);
  await tester.pumpAndSettle();
  return Get.find<ReturnsController>();
}

Finder _field(TextEditingController c) =>
    find.byWidgetPredicate((w) => w is TextField && w.controller == c);

Future<void> _bill(
  WidgetTester tester,
  ReturnsController page,
  String text,
) async {
  await tester.enterText(_field(page.billNumber), text);
  await tester.pump();
}

Future<void> _qty(
  WidgetTester tester,
  ReturnsController page,
  int id,
  String text,
) async {
  await tester.enterText(_field(page.fieldFor(id)), text);
  await tester.pump();
}

void main() {
  useTestApp();

  testWidgets('empty state: heading, title, box and the starting hint', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('MAISON GALAXY / RETAIL WORKSPACE'), findsOneWidget);
    expect(find.text('Returns'), findsWidgets);
    expect(find.text('Find a bill to return items'), findsOneWidget);
    expect(find.text('Bill number, e.g. AX000001'), findsOneWidget);
    expect(
      find.text('Enter a completed bill number to begin.'),
      findsOneWidget,
    );
    expect(find.text('Refund & restock'), findsNothing);
  });

  testWidgets('no match shows its message, blanks included', (tester) async {
    final page = await _open(tester);
    await _bill(tester, page, 'AX000099');
    expect(find.text('No matching bill found.'), findsOneWidget);
    expect(find.text('Enter a completed bill number to begin.'), findsNothing);
    await _bill(tester, page, '   ');
    expect(find.text('No matching bill found.'), findsOneWidget);
    await _bill(tester, page, '');
    expect(
      find.text('Enter a completed bill number to begin.'),
      findsOneWidget,
    );
  });

  testWidgets('a matching bill (trimmed, any case) lists its lines', (
    tester,
  ) async {
    final page = await _open(tester);
    await _bill(tester, page, '  ax000007 ');
    expect(find.text('Ananya Sharma · ₹129.80'), findsOneWidget);
    expect(find.text('Coca Cola 500ml'), findsOneWidget);
    expect(find.text('Available to return: 2'), findsOneWidget);
    expect(find.text('Pepsi 500ml'), findsOneWidget);
    expect(find.text('Available to return: 1.5'), findsOneWidget);
    expect(find.text('Refund & restock'), findsOneWidget);
    expect(page.fieldFor(0).text, '0');
  });

  testWidgets('both checks toast with the prototype texts', (tester) async {
    final page = await _open(tester);
    final toasts = Get.find<ToastController>();
    await _bill(tester, page, 'AX000007');
    await tester.tap(find.text('Refund & restock'));
    await tester.pump();
    expect(toasts.toasts.last.text, 'Select items to refund');
    expect(toasts.toasts.last.kind, ToastKind.warning);
    await _qty(tester, page, 0, '2.001');
    await tester.tap(find.text('Refund & restock'));
    await tester.pump();
    expect(
      toasts.toasts.last.text,
      'Refund quantity exceeds remaining sold quantity',
    );
    expect(toasts.toasts.last.kind, ToastKind.error);
    expect(Get.find<OverlayController>().isOpen, isFalse);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('negative and empty input become 0', (tester) async {
    final page = await _open(tester);
    await _bill(tester, page, 'AX000007');
    await _qty(tester, page, 0, '3');
    expect(page.qty[0], const Qty(3000));
    await _qty(tester, page, 0, '');
    expect(page.qty[0], Qty.zero);
    expect(page.fieldFor(0).text, '0');
    await _qty(tester, page, 0, '1.5');
    expect(page.qty[0], const Qty(1500));
    expect(page.fieldFor(0).text, '1.5');
    // typing after the initial "0" gives "01", which is the number 1
    await _qty(tester, page, 0, '01');
    expect(page.qty[0], const Qty(1000));
    expect(page.fieldFor(0).text, '1');
    await _qty(tester, page, 0, '0.5');
    expect(page.fieldFor(0).text, '0.5');
  });

  testWidgets('confirm text, refund effects and cleared quantities', (
    tester,
  ) async {
    final page = await _open(tester);
    final products = Get.find<ProductsController>();
    final overlay = Get.find<OverlayController>();
    final toasts = Get.find<ToastController>();
    final cola = products.byId(0)!.stock;
    await _bill(tester, page, 'AX000007');
    await _qty(tester, page, 0, '1');
    await tester.tap(find.text('Refund & restock'));
    await tester.pumpAndSettle();
    expect(overlay.modal.value, OverlayController.confirmId);
    expect(
      find.text('Refund ₹47.20 and restock selected items?'),
      findsOneWidget,
    );
    // nothing changed before the confirmation
    expect(products.byId(0)!.stock, cola);
    overlay.accept();
    await tester.pumpAndSettle();
    expect(products.byId(0)!.stock, cola + 1);
    expect(Get.find<SalesController>().sales.single.returned, const <int, Qty>{
      0: Qty(1000),
    });
    expect(page.qty, isEmpty);
    expect(page.fieldFor(0).text, '0');
    expect(page.billNumber.text, 'AX000007', reason: 'the number stays');
    expect(toasts.toasts.last.text, 'Refund completed: ₹47.20');
    expect(find.text('Available to return: 1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('a second partial refund and a fractional line', (tester) async {
    final page = await _open(tester);
    final products = Get.find<ProductsController>();
    final overlay = Get.find<OverlayController>();
    final chips = products.byId(1)!.stock;
    await _bill(tester, page, 'AX000007');
    await _qty(tester, page, 1, '1.5');
    await tester.tap(find.text('Refund & restock'));
    await tester.pumpAndSettle();
    // 129.80 * 30.00 / 110.00 = 35.40
    expect(
      find.text('Refund ₹35.40 and restock selected items?'),
      findsOneWidget,
    );
    overlay.accept();
    await tester.pumpAndSettle();
    // 1.5 units restock as whole units, rounded up (KG-106)
    expect(products.byId(1)!.stock, chips + 2);
    expect(find.text('Available to return: 0'), findsOneWidget);
    // the whole line is gone: returning anything more exceeds
    await _qty(tester, page, 1, '0.001');
    await tester.tap(find.text('Refund & restock'));
    await tester.pump();
    expect(
      Get.find<ToastController>().toasts.last.text,
      'Refund quantity exceeds remaining sold quantity',
    );
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('a new bill number clears the typed quantities', (tester) async {
    final page = await _open(tester);
    await _bill(tester, page, 'AX000007');
    await _qty(tester, page, 0, '1');
    expect(page.qty, isNotEmpty);
    await _bill(tester, page, 'AX00000');
    expect(page.qty, isEmpty);
    await _bill(tester, page, 'AX000007');
    expect(page.fieldFor(0).text, '0');
  });

  testWidgets('a refund does not change the sale totals or the ledger size', (
    tester,
  ) async {
    final page = await _open(tester);
    final sales = Get.find<SalesController>();
    await _bill(tester, page, 'AX000007');
    await _qty(tester, page, 0, '2');
    await tester.tap(find.text('Refund & restock'));
    await tester.pumpAndSettle();
    Get.find<OverlayController>().accept();
    await tester.pumpAndSettle();
    expect(sales.sales.length, 1);
    expect(sales.sales.single.totals.total, _inr(12980));
    await tester.pump(const Duration(seconds: 6));
  });
}
