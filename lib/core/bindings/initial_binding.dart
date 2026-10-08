import 'package:get/get.dart';

import '../../modules/shell/controllers/settings_controller.dart';
import '../../modules/shell/repository/mock_settings_repository.dart';
import '../../modules/shell/repository/settings_repository.dart';
import '../../shared/controllers/overlay_controller.dart';
import '../../shared/controllers/page_filter_controller.dart';
import '../../shared/controllers/search_field_controller.dart';
import '../../shared/controllers/shell_chrome_controller.dart';
import '../../shared/controllers/toast_controller.dart';
import '../services/storage/local_store.dart';

/// Permanent, cross-module controllers. Idempotent: calling it twice (from
/// `main` and from `GetMaterialApp.initialBinding`) registers once.
class InitialBinding extends Bindings {
  InitialBinding(this.store);

  final LocalStore store;

  @override
  void dependencies() {
    _put<LocalStore>(store);
    _put<SettingsRepository>(MockSettingsRepository(store));
    _put<SettingsController>(SettingsController(Get.find()));
    _put<ToastController>(ToastController());
    _put<SearchFieldController>(SearchFieldController());
    _put<PageFilterController>(PageFilterController());
    _put<ShellChromeController>(ShellChromeController());
    _put<OverlayController>(OverlayController());
  }

  void _put<T extends Object>(T instance) {
    if (!Get.isRegistered<T>()) Get.put<T>(instance, permanent: true);
  }
}
