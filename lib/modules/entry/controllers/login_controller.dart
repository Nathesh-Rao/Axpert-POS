import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../features/session/presentation/controllers/active_session.dart';
import '../../../core/theme/tokens/app_entry_tokens.dart';
import '../../../shared/controllers/toast_controller.dart';

/// Signs in against the users table (DEC-133): salted SHA-256, nothing is
/// stored, logged or sent; the password field is cleared before leaving the
/// screen. With one store and one counter the picker is skipped.
class LoginController extends GetxController {
  LoginController({
    required this.session,
    required this.onSignedIn,
    required this.onPick,
    Duration? fakeDelay,
  }) : fakeDelay =
           fakeDelay ??
           const Duration(milliseconds: AppEntryMotion.fakeLoginMs);

  final ActiveSession session;

  /// Opens the store and counter picker.
  final void Function(bool reducedMotion) onPick;

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

  /// Message under the fields after a failed sign-in.
  final RxnString error = RxnString();

  /// False when the database has no users (empty state); null until known.
  final RxnBool hasUsers = RxnBool();
  final RxBool usernameEmpty = false.obs;
  final RxBool passwordEmpty = false.obs;

  /// Set by the view from `MediaQuery.disableAnimations` (plain field).
  bool reducedMotion = false;

  @override
  void onReady() {
    super.onReady();
    session.hasUsers().then((value) {
      if (!isClosed) hasUsers.value = value;
    });
  }

  void toggleObscure() => obscure.toggle();

  void toggleRemember() => remember.toggle();

  /// Typing clears the error of that field.
  void usernameChanged(String _) {
    error.value = null;
    if (usernameEmpty.value) usernameEmpty.value = false;
  }

  void passwordChanged(String _) {
    error.value = null;
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
    error.value = null;
    final result = await session.signIn(username.text, password.text);
    if (isClosed) return;
    loading.value = false;
    if (!result.ok) {
      password.clear();
      error.value = result.failure == SignInFailure.noAccess
          ? AppStrings.current.loginNoAccess()
          : AppStrings.current.loginInvalid();
      passwordFocus.requestFocus();
      return;
    }
    password.clear();
    final only = session.onlyChoice;
    if (only == null) {
      onPick(reducedMotion);
      return;
    }
    loading.value = true;
    await session.begin(only.$1, only.$2);
    if (isClosed) return;
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
