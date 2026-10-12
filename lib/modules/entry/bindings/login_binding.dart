import 'package:get/get.dart';

import '../controllers/login_controller.dart';
import 'entry_navigation.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(
      () => LoginController(
        session: Get.find(),
        onSignedIn: EntryNavigation.toLanding,
        onPick: EntryNavigation.toPicker,
      ),
    );
  }
}
