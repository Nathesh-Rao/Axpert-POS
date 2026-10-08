import 'package:get/get.dart';

import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/controllers/toast_controller.dart';
import '../../products/controllers/products_controller.dart';
import '../../products/repository/product_repository.dart';
import '../../sales/controllers/sales_controller.dart';
import '../../sales/repository/sale_repository.dart';
import '../controllers/returns_controller.dart';
import '../repository/mock_return_repository.dart';
import '../repository/return_repository.dart';

class ReturnsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReturnRepository>(
      () => MockReturnRepository(
        sales: Get.find<SaleRepository>(),
        products: Get.find<ProductRepository>(),
      ),
    );
    Get.lazyPut<ReturnsController>(
      () => ReturnsController(
        sales: Get.find<SalesController>(),
        products: Get.find<ProductsController>(),
        repository: Get.find<ReturnRepository>(),
        toasts: Get.find<ToastController>(),
        overlay: Get.find<OverlayController>(),
      ),
    );
  }
}
