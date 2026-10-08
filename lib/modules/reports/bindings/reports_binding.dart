import 'package:get/get.dart';

import '../../shift/controllers/shift_controller.dart';
import '../controllers/reports_controller.dart';

class ReportsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportsController>(
      () => ReportsController(shift: Get.find<ShiftController>()),
    );
  }
}
