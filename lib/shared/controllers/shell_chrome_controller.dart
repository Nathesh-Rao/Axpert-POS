import 'package:get/get.dart';

enum ShellMenu { none, notifications, user }

/// Top bar state: online flag, unread badge, which popover is open.
class ShellChromeController extends GetxController {
  final RxBool online = true.obs;
  final RxBool unread = true.obs;
  final Rx<ShellMenu> menu = ShellMenu.none.obs;

  void toggleOnline() => online.value = !online.value;

  void toggleNotifications() {
    menu.value = menu.value == ShellMenu.notifications
        ? ShellMenu.none
        : ShellMenu.notifications;
    unread.value = false;
  }

  void toggleUserMenu() {
    menu.value = menu.value == ShellMenu.user ? ShellMenu.none : ShellMenu.user;
  }

  void closeMenu() => menu.value = ShellMenu.none;
}
