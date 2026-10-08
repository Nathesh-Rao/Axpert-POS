// The Sales page: newest first, filter, View receipt, empty state. VM tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';
import 'package:pos_application/modules/sales/controllers/sales_page_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/widgets/app_data_table.dart';

import '../../support/sale_fixtures.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

Future<void> _open(WidgetTester tester, {bool withSales = true}) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  if (withSales) {
    final at = DateTime(2026, 10, 8, 11, 16, 4);
    Get.find<SalesController>().sales.addAll(
      <dynamic>[
        testSale(number: 'AX000001', at: at, customer: 'Ananya Sharma'),
        testSale(
          number: 'AX000002',
          at: at.add(const Duration(minutes: 5)),
          mode: 'Card',
          totalMinor: 123456,
        ),
        testSale(
          number: 'AX000003',
          at: at.add(const Duration(minutes: 9)),
          customer: 'Rahul Verma',
          mode: 'Credit',
        ),
      ].cast(),
    );
  }
  Get.offAllNamed<void>(AppRoutes.sales);
  await tester.pumpAndSettle();
}

void main() {
  useTestApp();

  testWidgets('lists the sales newest first with the table columns', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('Sales'), findsWidgets);
    expect(find.text('Search sales...'), findsOneWidget);
    for (final head in <String>['Bill', 'Date', 'Customer', 'Mode', 'Total']) {
      expect(find.text(head), findsOneWidget, reason: head);
    }
    final page = Get.find<SalesPageController>();
    expect(page.rows.map((s) => s.number), <String>[
      'AX000003',
      'AX000002',
      'AX000001',
    ]);
    final y = <double>[
      for (final n in <String>['AX000003', 'AX000002', 'AX000001'])
        tester.getTopLeft(find.text(n)).dy,
    ];
    expect(y[0], lessThan(y[1]));
    expect(y[1], lessThan(y[2]));
    expect(find.text('₹1,234.56'), findsOneWidget);
    expect(find.text('Ananya Sharma'), findsOneWidget);
    expect(find.text('Credit'), findsOneWidget);
    expect(find.text('View receipt'), findsNWidgets(3));
    expect(find.text('Your first sale starts here'), findsNothing);
  });

  testWidgets('the filter matches the bill number and the customer', (
    tester,
  ) async {
    await _open(tester);
    final page = Get.find<SalesPageController>();
    page.filterNow('ax000002');
    await tester.pumpAndSettle();
    expect(page.rows.map((s) => s.number), <String>['AX000002']);
    page.filterNow('RAHUL');
    expect(page.rows.map((s) => s.number), <String>['AX000003']);
    page.filterNow('walk-in');
    expect(page.rows.map((s) => s.number), <String>['AX000002']);
    page.filterNow('card'); // the mode is not searched
    await tester.pumpAndSettle();
    expect(page.rows, isEmpty);
    // A filter with no match is not the empty ledger.
    expect(find.text('Your first sale starts here'), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('View receipt opens the receipt of that bill', (tester) async {
    await _open(tester);
    await tester.tap(find.text('View receipt').at(1)); // the middle row
    await tester.pumpAndSettle();
    expect(Get.find<OverlayController>().modal.value, 'receipt');
    expect(find.text('Bill: AX000002'), findsOneWidget);
    expect(find.text('₹1,234.56'), findsWidgets);
    Get.find<OverlayController>().close();
    await tester.pumpAndSettle();
  });

  testWidgets('the empty ledger shows the header and the empty state', (
    tester,
  ) async {
    await _open(tester, withSales: false);
    expect(find.text('Bill'), findsOneWidget);
    expect(find.byType(StockChip), findsNothing);
    expect(find.text('Your first sale starts here'), findsOneWidget);
    expect(
      find.text('Completed bills will appear here automatically.'),
      findsOneWidget,
    );
    expect(find.text('View receipt'), findsNothing);
    // A sale made meanwhile replaces the empty state.
    Get.find<SalesController>().sales.add(
      testSale(number: 'AX000001', at: DateTime(2026, 10, 8)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your first sale starts here'), findsNothing);
    expect(find.text('AX000001'), findsOneWidget);
  });

  testWidgets('View receipt is reachable by keyboard', (tester) async {
    await _open(tester);
    final target = find.text('View receipt').first;
    final focusable = find.ancestor(of: target, matching: find.byType(Focus));
    expect(focusable, findsWidgets);
  });
}
