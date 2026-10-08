import 'package:get/get.dart';

import '../../../shared/controllers/page_filter_controller.dart';
import '../../../shared/controllers/search_field_controller.dart';
import '../../products/controllers/products_controller.dart';
import '../controllers/catalog_controller.dart';

/// POS route binding. The catalog state (category, subcategory, view mode)
/// lives in the prototype's root component, so it survives page changes; the
/// controller is therefore registered once and kept (DEC-083).
class PosBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CatalogController>()) {
      Get.put<CatalogController>(
        CatalogController(
          products: Get.find<ProductsController>(),
          pageFilter: Get.find<PageFilterController>(),
          search: Get.find<SearchFieldController>(),
        ),
        permanent: true,
      );
    }
  }
}
