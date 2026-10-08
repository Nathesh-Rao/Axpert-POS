import 'dart:ui' show VoidCallback;

import 'package:get/get.dart';

import '../../shared/controllers/toast_controller.dart';
import '../constants/app_strings.dart';

/// What a global shortcut does. Screens replace the defaults when they exist
/// (S3: delete line, S4: payments, hold, recall, discount). Until then the
/// F-keys only show a "(demo)" toast.
enum ShortcutAction { cash, card, hold, recall, discount, deleteSelected }

class ShortcutController extends GetxController {
  late final Map<ShortcutAction, VoidCallback> handlers =
      <ShortcutAction, VoidCallback>{
        ShortcutAction.cash: () => _demo(AppStrings.current.shortcutCash()),
        ShortcutAction.card: () => _demo(AppStrings.current.shortcutCard()),
        ShortcutAction.hold: () => _demo(AppStrings.current.shortcutHold()),
        ShortcutAction.recall: () => _demo(AppStrings.current.shortcutRecall()),
        ShortcutAction.discount: () =>
            _demo(AppStrings.current.shortcutDiscount()),
        // Needs a selected cart line (S3); nothing to delete yet.
        ShortcutAction.deleteSelected: () {},
      };

  void _demo(String action) => Get.find<ToastController>().show(
    AppStrings.current.shortcutDemo(action: action),
  );

  void run(ShortcutAction action) => handlers[action]?.call();
}
