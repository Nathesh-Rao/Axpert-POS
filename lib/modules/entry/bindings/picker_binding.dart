import 'package:get/get.dart';

import '../controllers/picker_controller.dart';
import 'entry_navigation.dart';

class PickerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PickerController>(
      () => PickerController(
        session: Get.find(),
        onDone: EntryNavigation.toLanding,
      ),
    );
  }
}
