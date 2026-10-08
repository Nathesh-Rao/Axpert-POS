import 'package:get/get.dart';

import 'search_field_controller.dart';
import 'shell_chrome_controller.dart';

/// Which modal is open (the prototype's single `modal` string). Opening a
/// modal closes menus; closing refocuses the search field.
/// A pending confirmation: the question and what runs when it is accepted.
class Confirmation {
  const Confirmation({required this.text, required this.onConfirm});

  final String text;
  final void Function() onConfirm;
}

class OverlayController extends GetxController {
  static const String confirmId = 'confirm';

  final RxnString modal = RxnString();

  Confirmation? confirmation;

  bool get isOpen => modal.value != null;

  void open(String id) {
    Get.find<ShellChromeController>().closeMenu();
    modal.value = id;
  }

  /// Opens the confirm dialog (prototype `setConfirm`).
  void openConfirm(String text, void Function() onConfirm) {
    confirmation = Confirmation(text: text, onConfirm: onConfirm);
    open(confirmId);
  }

  /// Confirm button: closes first, then runs the action (as the prototype).
  void accept() {
    final pending = confirmation;
    close();
    pending?.onConfirm();
  }

  void close() {
    confirmation = null;
    modal.value = null;
    Get.find<SearchFieldController>().refocus();
  }
}
