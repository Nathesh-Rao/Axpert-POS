import 'package:get/get.dart';

import '../controllers/splash_controller.dart';
import 'entry_navigation.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(
      () => SplashController(onDone: EntryNavigation.toLogin),
    );
  }
}
