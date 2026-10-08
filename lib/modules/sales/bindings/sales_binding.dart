import 'package:get/get.dart';

import '../../../shared/controllers/page_filter_controller.dart';
import '../controllers/sales_controller.dart';
import '../controllers/sales_page_controller.dart';

class SalesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SalesPageController>(
      () => SalesPageController(
        ledger: Get.find<SalesController>(),
        pageFilter: Get.find<PageFilterController>(),
      ),
    );
  }
}
