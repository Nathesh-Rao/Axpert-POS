import 'package:get/get.dart';

import '../../../shared/controllers/page_filter_controller.dart';
import '../controllers/customers_controller.dart';
import '../controllers/customers_page_controller.dart';

class CustomersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomersPageController>(
      () => CustomersPageController(
        customers: Get.find<CustomersController>(),
        pageFilter: Get.find<PageFilterController>(),
      ),
    );
  }
}
