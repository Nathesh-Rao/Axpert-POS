// 10,000-product checks (S3.d): scoped rebuilds and timing numbers. Timing is
// printed for the report; there is no threshold (numbers depend on the
// machine). Runs on VM and Chrome.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/mock/large_dataset.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/pos/controllers/catalog_controller.dart';
import 'package:pos_application/modules/pos/models/catalog_taxonomy.dart';
import 'package:pos_application/modules/pos/widgets/catalog_product_card.dart';
import 'package:pos_application/shared/controllers/page_filter_controller.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';
import 'package:pos_application/shared/widgets/product_card.dart';
import 'package:pos_application/shared/widgets/search_text_field.dart';

import '../../support/pos_support.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

const int _count = 10000;

InMemoryLocalStore _bigStore() {
  final store = InMemoryLocalStore();
  final json = <Map<String, dynamic>>[
    for (final p in LargeDataset.products(_count)) p.toJson(),
  ];
  // The store keeps JSON text; seed it through the public API.
  store.write(StorageKeys.products, json);
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

  test('timing: filter, search and favourite on $_count products', () async {
    final h = await PosHarness.boot(store: _bigStore());
    expect(h.products.products.length, _count);

    var sw = Stopwatch()..start();
    await h.products.load();
    sw.stop();
    _report('products load (decode 10k json + index)', sw);

    sw = Stopwatch()..start();
    final c = Get.put(
      CatalogController(
        products: h.products,
        pageFilter: Get.find<PageFilterController>(),
        search: Get.find<SearchFieldController>(),
      ),
    );
    sw.stop();
    _report('catalog controller init (index + first filter)', sw);
    expect(c.filtered.length, _count);

    sw = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      c.selectCategory(
        i.isEven ? CatalogCategory.beverages : CatalogCategory.snacks,
      );
    }
    sw.stop();
    _report('category switch', sw, 20);

    c.selectCategory(CatalogCategory.allItems);
    sw = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      c.selectSub(i.isEven ? 'Chips' : null);
    }
    sw.stop();
    _report('subcategory switch', sw, 20);
    c.selectSub(null);

    // The text filter itself (the debounce only delays it).
    const queries = <String>['item 00042', 'ld099', 'snacks', 'zzzz', 'item'];
    sw = Stopwatch()..start();
    for (final q in queries) {
      Get.find<PageFilterController>().set(q);
      c.clearFilter(); // recompute path with an empty text for comparison
      Get.find<PageFilterController>().set(q);
    }
    sw.stop();
    _report('text filter set/clear (x${queries.length})', sw, queries.length);

    // Recompute with each query directly (no debounce): measure the filter.
    final recompute = Stopwatch();
    for (final q in queries) {
      final f = Get.find<PageFilterController>()..set(q);
      recompute.start();
      c.onFilterChangedNow(f.filter.value);
      recompute.stop();
    }
    _report('text filter recompute', recompute, queries.length);

    sw = Stopwatch()..start();
    final saved = h.products.toggleFavourite(7); // list and filter update here
    sw.stop();
    _report('favourite toggle (list + refilter, before saving)', sw);
    sw = Stopwatch()..start();
    await saved;
    sw.stop();
    _report('favourite toggle persist (encode 10k + store)', sw);

    final product = h.products.byId(1234)!;
    sw = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      h.actions.add(product);
    }
    sw.stop();
    _report('add to cart (reducer + totals + notify)', sw, 20);
    await h.cart.flush();
  });

  testWidgets('only visible cards are built; adding rebuilds only that card', (
    tester,
  ) async {
    useReferenceViewport(tester);
    final binding = await tester.runAsync(
      () => bootTestApp(store: _bigStore()),
    );
    await tester.pumpWidget(testApp(binding!));
    await tester.pumpAndSettle();
    final visible = find.byType(ProductCard).evaluate().length;
    expect(visible, greaterThan(10));
    expect(visible, lessThan(100)); // lazy: 10,000 products, a screenful built

    final catalogSearch = find.descendant(
      of: find.byType(SearchTextField),
      matching: find.byType(TextField),
    );

    // Adding one product rebuilds exactly its own card.
    CatalogProductCard.builds = 0;
    await tester.tap(find.byTooltip('Add Item 00003 Beverages').first);
    await tester.pump();
    expect(CatalogProductCard.builds, 1, reason: 'only the tapped card');

    // A filter that keeps the same first screen rebuilds nothing.
    CatalogProductCard.builds = 0;
    final sw = Stopwatch()..start();
    await tester.enterText(catalogSearch, 'item 000');
    await tester.pump(const Duration(milliseconds: 200));
    sw.stop();
    _report('widget: filter to 100 rows incl. frame', sw);
    expect(
      Get.find<CatalogController>().filtered.length,
      100,
      reason: 'ids 0..99 contain "item 000"',
    );
    expect(
      CatalogProductCard.builds,
      0,
      reason: 'same products in the same slots: cached cards are reused',
    );

    // A narrower filter builds only the cards that are new on screen.
    CatalogProductCard.builds = 0;
    await tester.enterText(catalogSearch, 'item 0004');
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      CatalogProductCard.builds,
      lessThanOrEqualTo(Get.find<CatalogController>().filtered.length),
      reason: 'only products new on screen are built',
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });
}
