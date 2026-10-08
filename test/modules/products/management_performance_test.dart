// 10,000 products and 10,000 customers on the S5.a pages: filter time and lazy
// rows. Timing is printed for the report (no threshold). VM tests.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/mock/large_dataset.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/customers/controllers/customers_page_controller.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/products/controllers/products_page_controller.dart';
import 'package:pos_application/shared/widgets/app_data_table.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

const int _count = 10000;

InMemoryLocalStore _bigStore() {
  final store = InMemoryLocalStore();
  store.write(StorageKeys.products, <Map<String, dynamic>>[
    for (final p in LargeDataset.products(_count)) p.toJson(),
  ]);
  store.write(StorageKeys.customers, <Map<String, dynamic>>[
    for (var i = 0; i < _count; i++)
      Customer(
        id: 'c$i',
        name: 'Customer ${i.toString().padLeft(5, '0')}',
        phone: '98${10000000 + i}',
        email: 'c$i@example.com',
        member: 'MG${100000 + i}',
        points: i % 500,
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

  testWidgets('10,000 rows: open, filter and lazy rows', (tester) async {
    useReferenceViewport(tester);
    final binding = await tester.runAsync(
      () => bootTestApp(store: _bigStore()),
    );
    await tester.pumpWidget(testApp(binding!));
    await tester.pumpAndSettle();

    var sw = Stopwatch()..start();
    Get.offAllNamed<void>(AppRoutes.products);
    await tester.pumpAndSettle();
    sw.stop();
    _report('open Products with 10,000 rows (index + first frame)', sw);
    final products = Get.find<ProductsPageController>();
    expect(products.rows.length, _count);
    final built = find.byType(StockChip).evaluate().length;
    expect(built, greaterThan(5));
    expect(built, lessThan(40), reason: 'lazy: $built rows built of $_count');

    for (final q in <String>['item 0004', 'ld09999', 'zzzz', 'beverages']) {
      sw = Stopwatch()..start();
      products.filterNow(q);
      sw.stop();
      _report('products filter "$q" (${products.rows.length} rows)', sw);
    }
    sw = Stopwatch()..start();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    sw.stop();
    _report('products frame after filtering to nothing', sw);
    products.filterNow('');
    await tester.pump(const Duration(milliseconds: 200));

    Get.offAllNamed<void>(AppRoutes.customers);
    sw = Stopwatch()..start();
    await tester.pumpAndSettle();
    sw.stop();
    _report('open Customers with 10,000 rows', sw);
    final customers = Get.find<CustomersPageController>();
    expect(customers.rows.length, _count);
    for (final q in <String>['customer 09999', '9810005', 'zzzz']) {
      sw = Stopwatch()..start();
      customers.filterNow(q);
      sw.stop();
      _report('customers filter "$q" (${customers.rows.length} rows)', sw);
    }
    customers.filterNow('');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  });
}
