import 'package:get/get.dart';

import '../../../shared/controllers/page_filter_controller.dart';
import '../controllers/products_controller.dart';
import '../controllers/products_page_controller.dart';

class ProductsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductsPageController>(
      () => ProductsPageController(
        products: Get.find<ProductsController>(),
        pageFilter: Get.find<PageFilterController>(),
      ),
    );
  }
}
