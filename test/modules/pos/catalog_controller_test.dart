import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/modules/pos/controllers/catalog_controller.dart';
import 'package:pos_application/modules/pos/models/catalog_taxonomy.dart';
import 'package:pos_application/shared/controllers/page_filter_controller.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';

import '../../support/pos_support.dart';
import '../../support/test_app.dart';

CatalogController _catalog(PosHarness h) => Get.put(
  CatalogController(
    products: h.products,
    pageFilter: Get.find<PageFilterController>(),
    search: Get.find<SearchFieldController>(),
  ),
);

List<int> _ids(CatalogController c) => c.filtered.map((p) => p.id).toList();

void main() {
  useTestApp();

  test('all items by default, categories partition the 20 products', () async {
    final h = await PosHarness.boot();
    final c = _catalog(h);
    expect(c.filtered.length, 20);
    final counts = <CatalogCategory, int>{};
    for (final cat in CatalogCategory.values) {
      c.selectCategory(cat);
      counts[cat] = c.filtered.length;
    }
    expect(counts[CatalogCategory.allItems], 20);
    expect(counts[CatalogCategory.favourites], 3);
    expect(counts[CatalogCategory.beverages], 8);
    expect(counts[CatalogCategory.snacks], 7);
    expect(counts[CatalogCategory.personalCare], 5);
  });

  test('subcategory filter, reset on category change', () async {
    final h = await PosHarness.boot();
    final c = _catalog(h);
    c.selectCategory(CatalogCategory.beverages);
    c.selectSub('Juices');
    expect(_ids(c), [12, 13, 14]);
    c.selectCategory(CatalogCategory.snacks);
    expect(c.sub.value, isNull);
    expect(c.filtered.length, 7);
    c.selectSub('Chips');
    expect(_ids(c), [5, 6]);
  });

  test('All Items and Favourites omit four subcategories (KG-019)', () {
    for (final cat in [CatalogCategory.allItems, CatalogCategory.favourites]) {
      expect(cat.subcategories, [
        'Soft Drinks',
        'Juices',
        'Water',
        'Chips',
        'Biscuits',
        'Confectionery',
      ]);
    }
    expect(CatalogCategory.personalCare.subcategories, [
      'Oral Care',
      'Bath & Body',
      'Hair Care',
    ]);
    expect(CatalogCategory.snacks.subcategories.last, 'Noodles');
  });

  testWidgets('text filter is debounced and matches name or code', (
    tester,
  ) async {
    final h = (await tester.runAsync(PosHarness.boot))!;
    final c = _catalog(h);
    final filter = Get.find<PageFilterController>();
    c.onFilterChanged('lays');
    await tester.pump(const Duration(milliseconds: 100));
    expect(c.filtered.length, 20);
    await tester.pump(const Duration(milliseconds: 60));
    expect(_ids(c), [5, 6]);
    c.onFilterChanged('PER00');
    await tester.pump(const Duration(milliseconds: 200));
    expect(c.filtered.length, 5);
    c.selectCategory(CatalogCategory.snacks);
    expect(c.filtered, isEmpty);
    c.onFilterChanged('zzz');
    await tester.pump(const Duration(milliseconds: 200));
    expect(c.filtered, isEmpty);
    c.resetFilters();
    expect(filter.filter.value, '');
    expect(c.category.value, CatalogCategory.allItems);
    expect(c.filtered.length, 20);
    await tester.pump(const Duration(seconds: 1));
  });

  test('clearing the page filter (sidebar) empties the field', () async {
    final h = await PosHarness.boot();
    final c = _catalog(h);
    final filter = Get.find<PageFilterController>();
    filter.set('coca');
    expect(c.filterText.text, 'coca');
    filter.clear();
    expect(c.filterText.text, '');
  });

  test('favourite toggle updates the favourites list', () async {
    final h = await PosHarness.boot();
    final c = _catalog(h);
    c.selectCategory(CatalogCategory.favourites);
    expect(_ids(c), [0, 5, 8]);
    await h.products.toggleFavourite(1);
    expect(_ids(c), [0, 1, 5, 8]);
    await h.products.toggleFavourite(0);
    expect(_ids(c), [1, 5, 8]);
  });
}
