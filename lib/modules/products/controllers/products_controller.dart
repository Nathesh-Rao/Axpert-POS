import 'package:get/get.dart';

import '../models/product.dart';
import '../repository/product_repository.dart';

/// Permanent product list with prebuilt lookup maps (id, barcode, lowercase
/// code) and the lowercase "name code" search strings used by the catalog.
class ProductsController extends GetxController {
  ProductsController(this._repository);

  final ProductRepository _repository;

  final RxList<Product> products = <Product>[].obs;

  Map<int, Product> _byId = <int, Product>{};
  Map<String, Product> _byBarcode = <String, Product>{};
  Map<String, Product> _byCode = <String, Product>{};
  Map<int, String> _searchKey = <int, String>{};

  Future<void> load() async {
    _index(await _repository.load());
  }

  Product? byId(int id) => _byId[id];

  /// Barcode (exact) or code (case-insensitive), as the prototype's scan does.
  Product? byScan(String value) {
    final text = value.trim();
    return _byBarcode[text] ?? _byCode[text.toLowerCase()];
  }

  /// Price check lookup: exact barcode or case-insensitive code, NOT trimmed
  /// (unlike the scan, KG-129).
  Product? byExact(String value) =>
      _byBarcode[value] ?? _byCode[value.toLowerCase()];

  /// Lowercase `"$name $code"`; the prototype filters on this string.
  String searchKey(Product product) =>
      _searchKey[product.id] ?? '${product.name} ${product.code}'.toLowerCase();

  /// Flips the favourite flag: the list and lookup maps change at once (only
  /// that product, no reindex), then the new list is persisted.
  Future<void> toggleFavourite(int id) {
    final index = products.indexWhere((p) => p.id == id);
    if (index < 0) return Future<void>.value();
    final updated = products[index].copyWith(
      favourite: !products[index].favourite,
    );
    _byId[id] = updated;
    _byBarcode[updated.barcode] = updated;
    _byCode[updated.code.toLowerCase()] = updated;
    products[index] = updated;
    return _repository.save(products.toList());
  }

  /// Subtracts sold units (`stock - qty`, as `complete()` does) and persists.
  Future<void> applyStockDeltas(Map<int, int> deltas) {
    for (var i = 0; i < products.length; i++) {
      final delta = deltas[products[i].id];
      if (delta == null) continue;
      final updated = products[i].copyWith(stock: products[i].stock - delta);
      _byId[updated.id] = updated;
      _byBarcode[updated.barcode] = updated;
      _byCode[updated.code.toLowerCase()] = updated;
      products[i] = updated;
    }
    return _repository.save(products.toList());
  }

  /// Adds returned whole units to the stock in memory (a refund, App.tsx
  /// 633-639); the caller persists through its own repository.
  void restock(Map<int, int> units) {
    for (var i = 0; i < products.length; i++) {
      final added = units[products[i].id];
      if (added == null || added == 0) continue;
      final updated = products[i].copyWith(stock: products[i].stock + added);
      _byId[updated.id] = updated;
      _byBarcode[updated.barcode] = updated;
      _byCode[updated.code.toLowerCase()] = updated;
      products[i] = updated;
    }
  }

  void _index(List<Product> list) {
    _byId = <int, Product>{for (final p in list) p.id: p};
    _byBarcode = <String, Product>{};
    _byCode = <String, Product>{};
    for (final p in list) {
      _byBarcode.putIfAbsent(p.barcode, () => p);
      _byCode.putIfAbsent(p.code.toLowerCase(), () => p);
    }
    _searchKey = <int, String>{
      for (final p in list) p.id: '${p.name} ${p.code}'.toLowerCase(),
    };
    products.assignAll(list);
  }
}
