import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/bindings/app_infrastructure.dart';
import 'core/bindings/initial_binding.dart';
import 'core/bindings/startup_timeline.dart';
import 'core/config/entry_config.dart';
import 'core/constants/app_strings.dart';
import 'core/responsive/responsive_layout.dart';
import 'core/routes/app_pages.dart';
import 'core/shortcuts/app_shortcuts.dart';
import 'core/routes/url_strategy.dart';
import 'core/services/storage/shared_prefs_local_store.dart';
import 'core/theme/app_theme.dart';
import 'features/session/presentation/controllers/active_session.dart';
import 'modules/shell/controllers/settings_controller.dart';
import 'modules/shell/widgets/dialog_layer.dart';
import 'modules/shift/controllers/shift_controller.dart';
import 'modules/shift/widgets/signed_out_layer.dart';
import 'shared/widgets/toast_layer.dart';

Future<void> main() async {
  StartupTimeline.mark('main start');
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategy();
  final prefs = await StartupTimeline.measure(
    'LocalStore open (SharedPreferences)',
    SharedPreferences.getInstance,
  );
  final infrastructure = await StartupTimeline.measure(
    'bootstrap (database + device context)',
    AppInfrastructure.bootstrap,
  );
  final binding = InitialBinding(
    SharedPrefsLocalStore(prefs),
    infrastructure: infrastructure,
  );
  StartupTimeline.measureSync('dependencies()', binding.dependencies);
  await StartupTimeline.measure('loadData (all)', binding.loadData);
  if (EntryConfig.skip) {
    await StartupTimeline.measure(
      'sign in (SKIP_ENTRY)',
      () => Get.find<ActiveSession>().autoSignIn(
        username: EntryConfig.skipUser.isEmpty ? null : EntryConfig.skipUser,
      ),
    );
  }
  StartupTimeline.mark('runApp called');
  runApp(PosApp(binding: binding));
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => StartupTimeline.mark('first frame built'),
  );
  unawaited(
    WidgetsBinding.instance.waitUntilFirstFrameRasterized.then((_) {
      StartupTimeline.mark('first frame rasterized');
      StartupTimeline.report();
    }),
  );
}

class PosApp extends StatelessWidget {
  const PosApp({required this.binding, this.initialRoute, super.key});

  final InitialBinding binding;

  /// Defaults to [EntryConfig.initialRoute] (splash, or POS with SKIP_ENTRY).
  final String? initialRoute;

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
              Positioned.fill(
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  child: AppShortcuts(child: SignedOutLayer(child: child!)),
                ),
              ),
              const DialogLayer(),
              const _ToastsUnlessSignedOut(),
            ],
          ),
        ),
        initialRoute: initialRoute ?? EntryConfig.initialRoute,
        getPages: AppPages.pages,
        unknownRoute: AppPages.unknown,
      ),
    );
  }
}

/// The prototype draws the toasts inside the app, so none shows on the
/// "Counter closed" screen.
class _ToastsUnlessSignedOut extends StatelessWidget {
  const _ToastsUnlessSignedOut();

  @override
  Widget build(BuildContext context) {
    final shift = Get.find<ShiftController>();
    return Obx(
      () =>
          shift.signedOut.value ? const SizedBox.shrink() : const ToastLayer(),
    );
  }
}
