import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/tokens/app_entry_tokens.dart';
import '../../../shared/controllers/toast_controller.dart';

/// Demo login: any non-empty username and password is accepted after a short
/// fake delay. Nothing is stored, logged or sent (the API/auth module comes
/// later); the password field is cleared before leaving the screen.
class LoginController extends GetxController {
  LoginController({required this.onSignedIn, Duration? fakeDelay})
    : fakeDelay =
          fakeDelay ?? const Duration(milliseconds: AppEntryMotion.fakeLoginMs);

  /// Navigates on to the landing page; receives whether motion is reduced.
  final void Function(bool reducedMotion) onSignedIn;
  final Duration fakeDelay;

  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  final FocusNode usernameFocus = FocusNode(debugLabel: 'login-username');
  final FocusNode passwordFocus = FocusNode(debugLabel: 'login-password');

  final RxBool obscure = true.obs;
  final RxBool loading = false.obs;
  final RxBool remember = true.obs;
  final RxBool usernameEmpty = false.obs;
  final RxBool passwordEmpty = false.obs;

  /// Set by the view from `MediaQuery.disableAnimations` (plain field).
  bool reducedMotion = false;

  void toggleObscure() => obscure.toggle();

  void toggleRemember() => remember.toggle();

  /// Typing clears the error of that field.
  void usernameChanged(String _) {
    if (usernameEmpty.value) usernameEmpty.value = false;
  }

  void passwordChanged(String _) {
    if (passwordEmpty.value) passwordEmpty.value = false;
  }

  Future<void> submit() async {
    if (loading.value) return;
    final noUser = username.text.trim().isEmpty;
    final noPass = password.text.isEmpty;
    usernameEmpty.value = noUser;
    passwordEmpty.value = noPass;
    if (noUser) {
      usernameFocus.requestFocus();
      return;
    }
    if (noPass) {
      passwordFocus.requestFocus();
      return;
    }
    loading.value = true;
    await Future<void>.delayed(fakeDelay);
    if (isClosed) return;
    password.clear();
    onSignedIn(reducedMotion);
  }

  /// Placeholders from the design that have no behavior yet (QR login,
  /// forgot password, language): a demo toast.
  void demoOnly(String feature) {
    Get.find<ToastController>().show(
      AppStrings.current.loginDemoToast(feature),
      kind: ToastKind.info,
    );
  }

  @override
  void onClose() {
    username.dispose();
    password.dispose();
    usernameFocus.dispose();
    passwordFocus.dispose();
    super.onClose();
  }
}
