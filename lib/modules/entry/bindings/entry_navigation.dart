import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/tokens/app_entry_tokens.dart';
import '../../pos/bindings/pos_binding.dart';
import '../../pos/views/pos_view.dart';
import '../views/login_view.dart';
import 'login_binding.dart';

/// The two animated hops of the entry flow. Named routes exist for both
/// pages too (see AppPages); these calls add the transition and its duration
/// (zero when motion is reduced).
abstract final class EntryNavigation {
  static Duration _duration(int ms, bool reduced) =>
      reduced ? Duration.zero : Duration(milliseconds: ms);

  /// Splash to login: route cross-fade while the logo flies into place.
  static void toLogin(bool reducedMotion) {
    Get.off<void>(
      () => const LoginView(),
      binding: LoginBinding(),
      routeName: AppRoutes.login,
      transition: Transition.fadeIn,
      duration: _duration(AppEntryMotion.splashToLoginMs, reducedMotion),
      curve: AppEntryMotion.splashToLoginCurve,
    );
  }

  /// Login to landing: clean fade onto the POS screen.
  static void toLanding(bool reducedMotion) {
    Get.offAll<void>(
      () => const PosView(),
      binding: PosBinding(),
      routeName: AppRoutes.pos,
      transition: Transition.fadeIn,
      duration: _duration(AppEntryMotion.loginToLandingMs, reducedMotion),
      curve: AppEntryMotion.loginToLandingCurve,
    );
  }
}
