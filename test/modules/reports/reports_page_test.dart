// The Reports page: tiles, bars and the footer from ShiftSummary. VM tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/utils/date_format.dart';
import 'package:pos_application/modules/reports/widgets/report_bar.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';
import 'package:pos_application/shared/widgets/management_page.dart';

import '../../support/sale_fixtures.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

Future<void> _open(WidgetTester tester) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  Get.offAllNamed<void>(AppRoutes.reports);
  await tester.pumpAndSettle();
}

List<double> _factors(WidgetTester tester) => <double>[
  for (final bar in tester.widgetList<ReportBar>(find.byType(ReportBar)))
    bar.basisPoints / 10000,
];

void main() {
  useTestApp();

  testWidgets('no sales: zeros, empty bars and today footer', (tester) async {
    await _open(tester);
    expect(find.text("Today's sales"), findsOneWidget);
    expect(find.text('Bills completed'), findsOneWidget);
    expect(find.text('Average bill'), findsOneWidget);
    expect(find.text('Sales by payment method'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ManagementPage),
        matching: find.text('₹0.00'),
      ),
      findsNWidgets(5),
    ); // 2 tiles + 3 bars
    expect(
      find.descendant(
        of: find.byType(ManagementPage),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );
    for (final mode in <String>['Cash', 'Card', 'Credit']) {
      expect(
        find.descendant(of: find.byType(ReportBar), matching: find.text(mode)),
        findsOneWidget,
        reason: mode,
      );
    }
    expect(_factors(tester), <double>[0, 0, 0]);
    expect(
      find.text(
        'Based on completed bills for ${DateFormatter.date(DateTime.now())}.',
      ),
      findsOneWidget,
    );
  });

  testWidgets("today's sales fill the tiles and bars; other days do not", (
    tester,
  ) async {
    await _open(tester);
    final now = DateTime.now();
    final noon = DateTime(now.year, now.month, now.day, 12);
    Get.find<SalesController>().sales.addAll(
      <dynamic>[
        testSale(number: '1', at: noon, mode: 'Cash', totalMinor: 30000),
        testSale(number: '2', at: noon, mode: 'Card', totalMinor: 50000),
        testSale(number: '3', at: noon, mode: 'Cash', totalMinor: 10000),
        testSale(number: '4', at: noon, mode: 'Credit', totalMinor: 10000),
        testSale(
          number: '5',
          at: noon.subtract(const Duration(days: 1)),
          totalMinor: 99900,
        ),
      ].cast(),
    );
    await tester.pumpAndSettle();
    expect(find.text('₹1,000.00'), findsOneWidget); // today's sales
    expect(find.text('4'), findsOneWidget); // bills
    expect(find.text('₹250.00'), findsOneWidget); // average
    expect(find.text('₹400.00'), findsOneWidget); // cash
    expect(find.text('₹500.00'), findsOneWidget); // card
    expect(find.text('₹100.00'), findsOneWidget); // credit
    expect(_factors(tester), <double>[0.4, 0.5, 0.1]);
  });

  testWidgets('the bar fills its share of the track', (tester) async {
    await _open(tester);
    final now = DateTime.now();
    Get.find<SalesController>().sales.addAll(
      <dynamic>[
        testSale(number: '1', at: now, mode: 'Card', totalMinor: 7000),
        testSale(number: '2', at: now, mode: 'Cash', totalMinor: 3000),
      ].cast(),
    );
    await tester.pumpAndSettle();
    final bars = find.descendant(
      of: find.byType(ReportBar),
      matching: find.byType(FractionallySizedBox),
    );
    final cash = tester.getSize(bars.at(0)).width; // 30 %
    final card = tester.getSize(bars.at(1)).width; // 70 %
    expect(card / cash, closeTo(70 / 30, 0.01));
    final empty = tester.getSize(bars.at(2)).width;
    expect(empty, 0);
  });
}
