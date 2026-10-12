// Splash and login goldens. Light at the reference viewport is compared (by
// eye) with reference_screenshots/splash.png and login.png; other sizes and
// dark are regression only.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/theme/tokens/app_entry_tokens.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';
import 'package:pos_application/main.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../support/test_app.dart';
import 'harness.dart';
import 'images.dart';

enum _Screen { splash, login }

Future<void> _pump(
  WidgetTester tester, {
  required _Screen screen,
  required bool dark,
  Size? size,
}) async {
  if (size == null) {
    useReferenceViewport(tester);
  } else {
    useLogicalViewport(tester, size);
  }
  final binding = await bootInWidgetTest(tester);
  AppTypography.useBundledFonts = true;
  if (dark) {
    await tester.runAsync(() => Get.find<SettingsController>().setDark(true));
  }
  await tester.pumpWidget(testApp(binding, initialRoute: AppRoutes.splash));
  await tester.pump();
  await settleImages(tester);
  if (screen == _Screen.splash) {
    // 1.5 s in: the logo has arrived, the bar is three quarters full.
    await tester.pump(const Duration(milliseconds: 1500));
    return;
  }
  await tester.tap(find.byType(Focus).first);
  await tester.pump(
    const Duration(milliseconds: AppEntryMotion.splashToLoginMs),
  );
  await tester.pump(
    const Duration(
      milliseconds: AppEntryMotion.formRiseDelayMs + AppEntryMotion.formRiseMs,
    ),
  );
  await tester.pump();
  await settleImages(tester);
}

void main() {
  useTolerantGoldens();
  useTestApp();

  final skipReason = fontsSkipReason();
  final skip = skipReason.isNotEmpty;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!skip) await loadTestFonts();
  });
  final prefix = skip ? '[$skipReason] ' : '';

  void golden(
    String name,
    String file,
    _Screen screen, {
    bool dark = false,
    Size? size,
  }) {
    testWidgets('$prefix$name', (tester) async {
      useRealShadows();
      try {
        await _pump(tester, screen: screen, dark: dark, size: size);
        await expectLater(
          find.byType(PosApp),
          matchesGoldenFile('goldens/$file.png'),
        );
      } finally {
        if (Get.isRegistered<ToastController>()) {
          Get.find<ToastController>().onClose();
        }
        restoreDefaultShadows();
      }
    }, skip: skip);
  }

  golden(
    'Splash light at the reference viewport',
    'entry_splash_light',
    _Screen.splash,
  );
  golden(
    'Splash dark 1280x720 (regression, unverified visually)',
    'entry_splash_dark_1280',
    _Screen.splash,
    dark: true,
    size: const Size(1280, 720),
  );
  golden(
    'Splash light 950x733 (regression, unverified visually)',
    'entry_splash_light_950',
    _Screen.splash,
    size: const Size(950, 733),
  );
  golden(
    'Login light at the reference viewport',
    'entry_login_light',
    _Screen.login,
  );
  golden(
    'Login light 1280x720 (regression, unverified visually)',
    'entry_login_light_1280',
    _Screen.login,
    size: const Size(1280, 720),
  );
  golden(
    'Login dark 1280x720 (regression, unverified visually)',
    'entry_login_dark_1280',
    _Screen.login,
    dark: true,
    size: const Size(1280, 720),
  );
  golden(
    'Login light 950x733 (regression, unverified visually)',
    'entry_login_light_950',
    _Screen.login,
    size: const Size(950, 733),
  );
  golden(
    'Login light tablet 1024x768 (regression, unverified visually)',
    'entry_login_light_1024',
    _Screen.login,
    size: const Size(1024, 768),
  );
}
