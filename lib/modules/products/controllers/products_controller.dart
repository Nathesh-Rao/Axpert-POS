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

  /// Lowercase `"$name $code"`; the prototype filters on this string.
  String searchKey(Product product) =>
      _searchKey[product.id] ?? '${product.name} ${product.code}'.toLowerCase();

  /// Flips the favourite flag and persists.
  Future<void> toggleFavourite(int id) async {
    final next = <Product>[
      for (final p in products)
        p.id == id ? p.copyWith(favourite: !p.favourite) : p,
    ];
    _index(next);
    await _repository.save(next);
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
