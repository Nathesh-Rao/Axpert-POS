// The Customers page: filter, table, "—" cells, Add Customer. VM tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/modules/customers/controllers/add_customer_controller.dart';
import 'package:pos_application/modules/customers/controllers/customers_page_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

Future<void> _open(WidgetTester tester) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  Get.offAllNamed<void>(AppRoutes.customers);
  await tester.pumpAndSettle();
}

void main() {
  useTestApp();

  testWidgets('shows the table with "—" for empty cells', (tester) async {
    await _open(tester);
    for (final head in <String>[
      'Name',
      'Phone',
      'Email',
      'Membership',
      'Points',
    ]) {
      expect(find.text(head), findsOneWidget, reason: head);
    }
    expect(find.text('Search customers...'), findsOneWidget);
    expect(find.text('Walk-in Customer'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(3)); // walk-in: phone, email, member
    expect(find.text('Ananya Sharma'), findsOneWidget);
    expect(find.text('9876543210'), findsOneWidget);
    expect(find.text('ananya@example.com'), findsOneWidget);
    expect(find.text('MG1001'), findsOneWidget);
    expect(find.text('250'), findsOneWidget);
  });

  testWidgets('the filter matches name and phone only', (tester) async {
    await _open(tester);
    final page = Get.find<CustomersPageController>();
    page.filterNow('rahul');
    expect(page.rows.map((c) => c.name), <String>['Rahul Mehta']);
    page.filterNow('9876543212');
    expect(page.rows.map((c) => c.name), <String>['Priya Nair']);
    page.filterNow('MG1001'); // the membership is not searched here
    expect(page.rows, isEmpty);
    page.filterNow('');
    expect(page.rows.length, 4);
    await tester.pump(const Duration(milliseconds: 200)); // debounce
  });

  testWidgets('Add Customer opens the dialog and the new row appears', (
    tester,
  ) async {
    await _open(tester);
    await tester.tap(find.text('Add Customer'));
    await tester.pumpAndSettle();
    expect(Get.find<OverlayController>().modal.value, 'addCustomer');
    final add = Get.find<AddCustomerController>();
    await tester.enterText(
      find.byWidgetPredicate((w) => w is TextField && w.controller == add.name),
      'Ravi Kumar',
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.controller == add.phone,
      ),
      '9845011111',
    );
    await tester.tap(find.text('Save customer'));
    await tester.pumpAndSettle();
    expect(Get.find<CustomersPageController>().rows.length, 5);
    expect(find.text('Ravi Kumar'), findsWidgets);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });
}
