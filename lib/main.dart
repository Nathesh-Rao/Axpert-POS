import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/bindings/initial_binding.dart';
import 'core/constants/app_strings.dart';
import 'core/responsive/responsive_layout.dart';
import 'core/routes/app_pages.dart';
import 'core/shortcuts/app_shortcuts.dart';
import 'core/routes/url_strategy.dart';
import 'core/services/storage/shared_prefs_local_store.dart';
import 'core/theme/app_theme.dart';
import 'modules/shell/controllers/settings_controller.dart';
import 'modules/shell/widgets/dialog_host.dart';
import 'shared/widgets/toast_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  final prefs = await SharedPreferences.getInstance();
  final binding = InitialBinding(SharedPrefsLocalStore(prefs));
  binding.dependencies();
  await Get.find<SettingsController>().load();
  runApp(PosApp(binding: binding));
}

class PosApp extends StatelessWidget {
  const PosApp({required this.binding, super.key});

  final InitialBinding binding;

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppStrings.current.appTitle(),
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: settings.dark ? ThemeMode.dark : ThemeMode.light,
        initialBinding: binding,
        builder: (context, child) => ResponsiveLayout(
          child: Stack(
            children: <Widget>[
              Positioned.fill(child: AppShortcuts(child: child!)),
              const DialogHost(),
              const ToastHost(),
            ],
          ),
        ),
        getPages: AppPages.pages,
        unknownRoute: AppPages.unknown,
      ),
    );
  }
}
