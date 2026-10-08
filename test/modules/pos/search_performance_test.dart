// 10,000 products and 10,000 customers (S4.c): timing of the search, the
// dropdown and the customer filter, and lazy lists. Timing is printed for the
// report; there is no threshold (numbers depend on the machine). Runs on VM and
// Chrome.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/mock/large_dataset.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/customers/controllers/customer_picker_controller.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/pos/controllers/global_search_controller.dart';
import 'package:pos_application/modules/pos/widgets/catalog_product_card.dart';
import 'package:pos_application/modules/pos/services/product_search.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/modules/shell/widgets/search_results.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';
import 'package:pos_application/shared/widgets/modal_list_row.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

const int _count = 10000;

InMemoryLocalStore _bigStore() {
  final store = InMemoryLocalStore();
  store.write(StorageKeys.products, <Map<String, dynamic>>[
    for (final p in LargeDataset.products(_count)) p.toJson(),
  ]);
  store.write(StorageKeys.customers, <Map<String, dynamic>>[
    const Customer(
      id: 'walk',
      name: 'Walk-in Customer',
      phone: '',
      email: '',
      member: '',
      points: 0,
    ).toJson(),
    for (var i = 0; i < _count; i++)
      Customer(
        id: 'c$i',
        name: 'Customer ${i.toString().padLeft(5, '0')}',
        phone: '98${(10000000 + i)}',
        email: '',
        member: 'MG${100000 + i}',
        points: i % 500,
      ).toJson(),
  ]);
  return store;
}

void _report(String label, Stopwatch sw, [int runs = 1]) {
  // ignore: avoid_print
  print(
    'PERF $label: ${(sw.elapsedMicroseconds / runs / 1000).toStringAsFixed(3)} ms'
    '${runs > 1 ? ' (mean of $runs)' : ''}',
  );
}

void main() {
  useTestApp();

  test('timing: product search and customer filter on 10,000 rows', () async {
    await bootTestApp(store: _bigStore());
    final products = Get.find<ProductsController>();
    expect(products.products.length, _count);
    final picker = Get.find<CustomerPickerController>();
    expect(picker.customers.customers.length, _count + 1);

    // The match function alone (what the dropdown and Enter run).
    const queries = <String, String>{
      'common ("item", stops after 6)': 'item',
      'late hit ("ld09999")': 'ld09999',
      'no match ("zzzz", walks all 10,000)': 'zzzz',
    };
    queries.forEach((label, q) {
      const runs = 50;
      final sw = Stopwatch()..start();
      for (var i = 0; i < runs; i++) {
        ProductSearch.matches(products.products, products.searchKey, q);
      }
      sw.stop();
      _report('product matches $label', sw, runs);
    });

    // The controller path: matches + assign to the Rx list + highlight reset.
    final search = Get.find<SearchFieldController>();
    final global = Get.find<GlobalSearchController>();
    var sw = Stopwatch()..start();
    for (var i = 0; i < 50; i++) {
      search.text.text = i.isEven ? 'item 0004' : 'ld0999';
      global.refreshNow();
    }
    sw.stop();
    _report('dropdown refresh (matches + notify)', sw, 50);

    // Customers: the debounced refilter, called directly.
    for (final q in <String>['customer', 'customer 099', 'mg1000', 'zzzz']) {
      picker.search.text = q;
      sw = Stopwatch()..start();
      picker.refilter();
      sw.stop();
      _report('customer filter "$q" (${picker.filtered.length} rows)', sw);
    }
    expect(picker.filtered, isEmpty);
  });

  testWidgets('typing builds at most the dropdown; pickers stay lazy', (
    tester,
  ) async {
    useReferenceViewport(tester);
    final binding = await tester.runAsync(
      () => bootTestApp(store: _bigStore()),
    );
    await tester.pumpWidget(testApp(binding!));
    await tester.pumpAndSettle();

    final search = Get.find<SearchFieldController>();
    search.focusNode.requestFocus();
    await tester.pump();
    final field = find.byWidgetPredicate(
      (w) => w is TextField && w.controller == search.text,
    );

    // Typing builds only the six dropdown rows and no catalog card.
    CatalogProductCard.builds = 0;
    SearchResultsPortal.rowBuilds = 0;
    var sw = Stopwatch()..start();
    await tester.enterText(field, 'item 0004');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    sw.stop();
    _report('widget: type "item 0004" to dropdown incl. frame', sw);
    expect(Get.find<GlobalSearchController>().matches.length, 6);
    expect(
      SearchResultsPortal.rowBuilds,
      lessThanOrEqualTo(12),
      reason: 'the six rows (a rebuild or two at most)',
    );
    expect(CatalogProductCard.builds, 0, reason: 'the catalog is untouched');

    // A second keystroke refreshes the same six rows.
    SearchResultsPortal.rowBuilds = 0;
    sw = Stopwatch()..start();
    await tester.enterText(field, 'item 00041');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    sw.stop();
    _report('widget: refine to "item 00041" incl. frame', sw);
    expect(SearchResultsPortal.rowBuilds, lessThanOrEqualTo(12));
    search.text.clear();
    await tester.pump(const Duration(milliseconds: 200));

    // 10,001 customers: only the visible rows are built.
    sw = Stopwatch()..start();
    Get.find<OverlayController>().open('customers');
    await tester.pumpAndSettle();
    sw.stop();
    _report('widget: open the picker with 10,001 customers', sw);
    final rows = find.byType(ModalListRow).evaluate().length;
    expect(rows, greaterThan(0));
    expect(rows, lessThan(30), reason: 'lazy list: $rows rows built');

    final picker = Get.find<CustomerPickerController>();
    sw = Stopwatch()..start();
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.controller == picker.search,
      ),
      'customer 09999',
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    sw.stop();
    _report('widget: filter 10,001 customers to ${picker.filtered.length}', sw);
    expect(picker.filtered.length, 1);
    Get.find<OverlayController>().close();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });
}
