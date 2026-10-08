import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../shared/controllers/page_filter_controller.dart';
import '../../../shared/controllers/search_field_controller.dart';
import '../../products/controllers/products_controller.dart';
import '../../products/models/product.dart';
import '../models/catalog_taxonomy.dart';

/// Catalog state: category, subcategory, grid/list and the filtered product
/// list. The list is recomputed only when an input changes (never in `build`);
/// typed text is debounced. Filter text is the shared page filter (KG-027).
class CatalogController extends GetxController {
  CatalogController({
    required this.products,
    required this.pageFilter,
    required this.search,
  });

  static const Duration debounceDuration = Duration(milliseconds: 150);

  final ProductsController products;
  final PageFilterController pageFilter;
  final SearchFieldController search;

  final Rx<CatalogCategory> category = CatalogCategory.allItems.obs;

  /// Selected subcategory, null = "All".
  final Rxn<String> sub = Rxn<String>();
  final RxBool list = false.obs;
  final RxList<Product> filtered = <Product>[].obs;

  /// Text of the catalog search field (mirrors [PageFilterController]).
  final TextEditingController filterText = TextEditingController();

  List<(Product, String)> _entries = <(Product, String)>[];
  String _appliedFilter = '';

  @override
  void onInit() {
    super.onInit();
    _rebuildEntries();
    filterText.text = pageFilter.filter.value;
    _appliedFilter = pageFilter.filter.value;
    _recompute();
    ever(products.products, (_) {
      _rebuildEntries();
      _recompute();
    });
    ever(category, (_) => _recompute());
    ever(sub, (_) => _recompute());
    debounce(pageFilter.filter, (String value) {
      _appliedFilter = value;
      _recompute();
    }, time: debounceDuration);
    // Navigation clears the shared filter: keep the field in sync.
    ever(pageFilter.filter, (String value) {
      if (filterText.text != value) filterText.text = value;
    });
  }

  void selectCategory(CatalogCategory next) {
    category.value = next;
    sub.value = null;
    search.refocus();
  }

  void selectSub(String? name) {
    sub.value = name;
    search.refocus();
  }

  void setList(bool value) => list.value = value;

  void onFilterChanged(String value) => pageFilter.set(value);

  void clearFilter() {
    pageFilter.clear();
    _appliedFilter = '';
    _recompute();
    search.refocus();
  }

  /// "Reset filters" in the empty state.
  void resetFilters() {
    pageFilter.clear();
    _appliedFilter = '';
    category.value = CatalogCategory.allItems;
    sub.value = null;
    _recompute();
  }

  void _rebuildEntries() {
    _entries = <(Product, String)>[
      for (final p in products.products) (p, products.searchKey(p)),
    ];
  }

  void _recompute() {
    final cat = category.value;
    final subName = sub.value;
    final text = _appliedFilter.toLowerCase();
    final result = <Product>[];
    for (final (product, key) in _entries) {
      if (cat == CatalogCategory.favourites) {
        if (!product.favourite) continue;
      } else if (cat.dataName != null && product.category != cat.dataName) {
        continue;
      }
      if (subName != null && product.sub != subName) continue;
      if (text.isNotEmpty && !key.contains(text)) continue;
      result.add(product);
    }
    filtered.assignAll(result);
  }

  @override
  void onClose() {
    filterText.dispose();
    super.onClose();
  }
}
