import 'package:get/get.dart';

import 'search_field_controller.dart';
import 'shell_chrome_controller.dart';

/// Which modal is open (the prototype's single `modal` string). Opening a
/// modal closes menus; closing refocuses the search field.
class OverlayController extends GetxController {
  final RxnString modal = RxnString();

  bool get isOpen => modal.value != null;

  void open(String id) {
    Get.find<ShellChromeController>().closeMenu();
    modal.value = id;
  }

  void close() {
    modal.value = null;
    Get.find<SearchFieldController>().refocus();
  }
}
