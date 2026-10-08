import 'package:get/get.dart';

import '../../../shared/controllers/filtered_list_controller.dart';
import '../models/product.dart';
import 'products_controller.dart';

/// The Products page: the product list filtered by `name code barcode`.
class ProductsPageController extends FilteredListController<Product> {
  ProductsPageController({required this.products, required super.pageFilter});

  final ProductsController products;

  @override
  RxList<Product> get source => products.products;

  @override
  String keyOf(Product item) =>
      '${item.name} ${item.code} ${item.barcode}'.toLowerCase();
}
