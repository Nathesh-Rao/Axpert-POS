import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/bindings/initial_binding.dart';
import 'core/constants/app_strings.dart';
import 'core/responsive/responsive_layout.dart';
import 'core/routes/app_pages.dart';
import 'core/routes/url_strategy.dart';
import 'core/services/storage/shared_prefs_local_store.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/debug/theme_swatch_page.dart';
import 'modules/shell/controllers/settings_controller.dart';

// TEMPORARY (DEC-065): debug-only swatch, deleted in S2.d.
const bool _swatchFlag = bool.fromEnvironment('SWATCH');

bool get _showSwatch =>
    kDebugMode &&
    (_swatchFlag || Uri.base.queryParameters.containsKey('swatch'));

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
        builder: (context, child) => ResponsiveLayout(child: child!),
        getPages: AppPages.pages,
        unknownRoute: AppPages.unknown,
        home: _showSwatch ? const ThemeSwatchPage() : null,
      ),
    );
  }
}
