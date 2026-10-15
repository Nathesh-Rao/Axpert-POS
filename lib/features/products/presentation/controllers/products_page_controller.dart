import 'package:get/get.dart';

import '../../../../core/shortcuts/shortcut_controller.dart';
import '../../../../shared/controllers/filtered_list_controller.dart';
import '../../domain/entities/product.dart';
import 'product_admin_controller.dart';
import 'products_controller.dart';

/// The Products page: the product list filtered by `name code barcode`.
class ProductsPageController extends FilteredListController<Product> {
  ProductsPageController({
    required this.products,
    required super.pageFilter,
    required this.admin,
  });

  final ProductsController products;
  final ProductAdminController admin;

  @override
  RxList<Product> get source => products.products;

  @override
  String keyOf(Product item) =>
      '${item.name} ${item.code} ${item.barcode}'.toLowerCase();

  /// After the first frame (never during build): the stock cells and the
  /// inactive list.
  @override
  void onReady() {
    super.onReady();
    if (!admin.canManage) return;
    admin.reloadLists();
    Get.find<ShortcutController>().handlers[ShortcutAction.newProduct] =
        admin.openAddFromShortcut;
  }

  @override
  void onClose() {
    if (Get.isRegistered<ShortcutController>()) {
      Get.find<ShortcutController>().handlers[ShortcutAction.newProduct] =
          () {};
    }
    super.onClose();
  }

  /// Inactive products matching the search text, shown after the active ones
  /// while "Show inactive" is on.
  List<Product> get inactiveRows {
    if (!admin.showInactive.value) return const <Product>[];
    final text = pageFilter.filter.value.trim().toLowerCase();
    return [
      for (final p in admin.inactive)
        if (text.isEmpty || keyOf(p).contains(text)) p,
    ];
  }
}
