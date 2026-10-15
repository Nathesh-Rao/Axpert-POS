// Bill Summary goldens of stores whose tax and forex come from the database:
// a VAT store with forex rows (single tax line, no CGST/SGST) and a store with
// no forex rows (the forex card is hidden). Regression only, not compared with
// React (the prototype has one GST line and a fixed forex card).

@Tags(<String>['golden'])
@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/features/session/domain/entities/session_entities.dart';
import 'package:pos_application/features/session/presentation/controllers/active_session.dart';
import 'package:pos_application/main.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/shared/controllers/clock_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../support/test_app.dart';
import '../support/test_session.dart';
import '../support/test_tax.dart';
import 'harness.dart';
import 'images.dart';

const _vatForex = <ForexRate>[
  ForexRate(code: 'USD', rateMicro: 83200000),
  ForexRate(code: 'EUR', rateMicro: 90500000),
  ForexRate(code: 'KES', rateMicro: 28500000),
];

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
    String file, {
    required ActiveSession Function() session,
    bool dark = false,
  }) {
    testWidgets('$prefix$name', (tester) async {
      useRealShadows();
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        useReferenceViewport(tester);
        final binding = await bootInWidgetTest(tester, session: session());
        AppTypography.useBundledFonts = true;
        Get.delete<ClockController>(force: true);
        Get.put<ClockController>(
          ClockController(now: () => DateTime(2026, 10, 7, 16, 57, 8)),
          permanent: true,
        );
        if (dark) {
          await tester.runAsync(
            () => Get.find<SettingsController>().setDark(true),
          );
        }
        await tester.pumpWidget(testApp(binding));
        await tester.pumpAndSettle();
        await settleImages(tester);
        final lays = Get.find<ProductsController>().byId(5)!;
        Get.find<CartActionsController>().add(lays);
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        Get.find<ToastController>().toasts.clear();
        await tester.pumpAndSettle();
        await settleImages(tester);
        await expectGolden(find.byType(PosApp), file);
      } finally {
        if (Get.isRegistered<ToastController>()) {
          Get.find<ToastController>().onClose();
        }
        debugDefaultTargetPlatformOverride = null;
        restoreDefaultShadows();
      }
    }, skip: skip);
  }

  for (final dark in <bool>[false, true]) {
    final mode = dark ? 'dark' : 'light';
    golden(
      'Bill Summary of a VAT store with forex ($mode)',
      'summary_vat_forex_$mode',
      dark: dark,
      session: () => storeSession(regime: testVatRegime, forex: _vatForex),
    );
    golden(
      'Bill Summary of a store without forex ($mode)',
      'summary_no_forex_$mode',
      dark: dark,
      session: () => storeSession(regime: testVatRegime),
    );
  }
}
