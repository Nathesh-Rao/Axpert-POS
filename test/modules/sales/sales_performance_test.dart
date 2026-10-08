// 10,000 sales on the Sales and Reports pages: open, filter, lazy rows and the
// summary. Timing is printed for the report (no threshold). VM tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/sales/controllers/sales_page_controller.dart';
import 'package:pos_application/modules/shift/controllers/shift_controller.dart';
import 'package:pos_application/modules/shift/services/shift_summary.dart';
import 'package:pos_application/shared/widgets/app_data_table.dart';

import '../../support/sale_fixtures.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

const int _count = 10000;

InMemoryLocalStore _bigStore(DateTime now) {
  final store = InMemoryLocalStore();
  store.write(StorageKeys.sales, <Map<String, dynamic>>[
    for (var i = 0; i < _count; i++)
      testSale(
        number: 'AX${(i + 1).toString().padLeft(6, '0')}',
        // Every third sale is today, the rest on earlier days.
        at: i % 3 == 0
            ? DateTime(now.year, now.month, now.day, 9, i % 60)
            : DateTime(
                now.year,
                now.month,
                now.day,
                9,
              ).subtract(Duration(days: 1 + i % 30)),
        customer: 'Customer ${i % 500}',
        mode: <String>['Cash', 'Card', 'Credit'][i % 3],
        totalMinor: 1000 + i,
      ).toJson(),
  ]);
  return store;
}

void _report(String label, Stopwatch sw, [int runs = 1]) {
  // ignore: avoid_print
  print(
    'PERF $label: ${(sw.elapsedMicroseconds / runs / 1000).toStringAsFixed(2)} ms'
    '${runs > 1 ? ' (mean of $runs)' : ''}',
  );
}

void main() {
  useTestApp();

  testWidgets('10,000 sales: open, filter, lazy rows, summary', (tester) async {
    useReferenceViewport(tester);
    final now = DateTime.now();
    final binding = await tester.runAsync(
      () => bootTestApp(store: _bigStore(now)),
    );
    await tester.pumpWidget(testApp(binding!));
    await tester.pumpAndSettle();

    var sw = Stopwatch()..start();
    Get.offAllNamed<void>(AppRoutes.sales);
    await tester.pumpAndSettle();
    sw.stop();
    _report('open Sales (10k rows, first frame)', sw);
    final page = Get.find<SalesPageController>();
    expect(page.rows.length, _count);
    expect(page.rows.first.number, 'AX010000'); // newest first
    final built = find.byType(TableText).evaluate().length;
    // ignore: avoid_print
    print('PERF rows built of $_count: ${built ~/ 6} (cells $built)');
    expect(built ~/ 6, lessThan(60));

    sw = Stopwatch()..start();
    page.filterNow('ax00500');
    sw.stop();
    _report('filter by bill number', sw);
    expect(page.rows.length, 10);
    sw = Stopwatch()..start();
    page.filterNow('customer 42');
    sw.stop();
    _report('filter by customer', sw);
    expect(page.rows.length, greaterThan(0));
    sw = Stopwatch()..start();
    page.filterNow('');
    sw.stop();
    _report('clear filter (10k rows)', sw);
    await tester.pumpAndSettle();

    final shift = Get.find<ShiftController>();
    sw = Stopwatch()..start();
    ShiftSummary? summary;
    for (var i = 0; i < 20; i++) {
      summary = shift.today;
    }
    sw.stop();
    _report('ShiftSummary over 10k sales (parse + sum)', sw, 20);
    expect(summary!.count, (_count / 3).ceil());

    sw = Stopwatch()..start();
    Get.offAllNamed<void>(AppRoutes.reports);
    await tester.pumpAndSettle();
    sw.stop();
    _report('open Reports (10k sales, first frame)', sw);
    await tester.pump(const Duration(milliseconds: 200));
  });
}
