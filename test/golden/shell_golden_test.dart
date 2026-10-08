// Shell goldens. Light at the reference viewport is compared (by eye) with
// reference_screenshots/; other sizes and dark are regression only.

@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';
import 'package:pos_application/main.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/shared/controllers/clock_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../support/test_app.dart';
import 'images.dart';
import 'harness.dart';

Future<void> _pump(
  WidgetTester tester, {
  required String route,
  bool dark = false,
  Size? logicalSize,
  Future<void> Function(WidgetTester tester)? after,
}) async {
  if (logicalSize == null) {
    useReferenceViewport(tester);
  } else {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = logicalSize;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  final binding = await bootInWidgetTest(tester);
  AppTypography.useBundledFonts = true;
  // A fixed clock (the reference screenshot shows 07/10/2026 16:57:08).
  Get.delete<ClockController>(force: true);
  Get.put<ClockController>(
    ClockController(now: () => DateTime(2026, 10, 7, 16, 57, 8)),
    permanent: true,
  );
  if (dark) {
    await tester.runAsync(() => Get.find<SettingsController>().setDark(true));
  }
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  await settleImages(tester);
  if (route != AppRoutes.pos) {
    Get.offAllNamed<void>(route);
    await tester.pumpAndSettle();
  }
  await after?.call(tester);
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

  // The reference screenshots are from macOS (the shortcut chip reads the
  // glyph). Foundation debug vars must be reset inside the test body.
  void golden(
    String name,
    String file, {
    String route = AppRoutes.pos,
    bool dark = false,
    Size? size,
    Future<void> Function(WidgetTester tester)? after,
  }) {
    testWidgets('$prefix$name', (tester) async {
      useRealShadows();
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await _pump(
          tester,
          route: route,
          dark: dark,
          logicalSize: size,
          after: after,
        );
        await expectLater(
          find.byType(PosApp),
          matchesGoldenFile('goldens/$file.png'),
        );
      } finally {
        if (Get.isRegistered<ToastController>()) {
          Get.find<ToastController>().onClose(); // cancel pending timers
        }
        debugDefaultTargetPlatformOverride = null;
        restoreDefaultShadows();
      }
    }, skip: skip);
  }

  golden('POS light, reference viewport', 'shell_pos_light');
  golden(
    'Customers light, reference viewport',
    'shell_customers_light',
    route: AppRoutes.customers,
  );
  golden(
    'Dialog and toast over POS (unverified visually)',
    'shell_dialog_toast',
    after: (tester) async {
      Get.find<OverlayController>().open('profile');
      Get.find<ToastController>().show('Store switched');
      await tester.pumpAndSettle();
    },
  );
  Future<void> addLays(WidgetTester tester) async {
    final lays = Get.find<ProductsController>().byId(5)!;
    Get.find<CartActionsController>().add(lays);
    await tester.pump();
    await tester.pump(const Duration(seconds: 2)); // highlight ends
    Get.find<ToastController>().toasts.clear();
    await tester.pumpAndSettle();
    await settleImages(tester);
  }

  golden(
    'POS with one line (Lays Classic), reference viewport',
    'pos_one_line_light',
    after: addLays,
  );
  for (final size in const <Size>[
    Size(1440, 900),
    Size(1100, 700),
    Size(950, 733),
  ]) {
    final w = size.width.toInt();
    golden(
      'POS with one line at ${w}x${size.height.toInt()} '
          '(regression, unverified visually)',
      'pos_one_line_light_$w',
      size: size,
      after: addLays,
    );
  }
  golden('POS dark (unverified visually)', 'shell_pos_dark', dark: true);
  for (final size in const <Size>[
    Size(1700, 960),
    Size(1280, 800),
    Size(1100, 700),
  ]) {
    final w = size.width.toInt();
    golden(
      'POS light at ${w}x${size.height.toInt()} (regression)',
      'shell_pos_light_$w',
      size: size,
    );
  }
}
