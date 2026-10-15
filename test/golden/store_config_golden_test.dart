// The Store configuration page (admin, India store with CGST + SGST slabs and
// two exchange rates), light and dark at the reference viewport. Regression
// only: the page has no React original.

@Tags(<String>['golden'])
@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';
import 'package:pos_application/features/store_config/data/in_memory_store_config_repository.dart';
import 'package:pos_application/features/store_config/domain/entities/store_config.dart';
import 'package:pos_application/features/store_config/domain/repositories/store_config_repository.dart';
import 'package:pos_application/features/store_config/domain/services/legacy_slabs.dart';
import 'package:pos_application/main.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/shared/controllers/clock_controller.dart';

import '../support/test_app.dart';
import '../support/test_session.dart';
import '../support/test_tax.dart';
import 'harness.dart';

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

  for (final dark in <bool>[false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('${prefix}Store configuration ($mode)', (tester) async {
      useRealShadows();
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        useReferenceViewport(tester);
        final binding = await bootInWidgetTest(
          tester,
          session: roleSession('admin'),
        );
        AppTypography.useBundledFonts = true;
        Get.put<StoreConfigRepository>(
          InMemoryStoreConfigRepository({
            'test-ozone': StoreConfig(
              storeId: 'test-ozone',
              name: 'MAISON GALAXY - OZONE',
              countryCode: 'IN',
              stateCode: 'Karnataka',
              currencyCode: 'INR',
              forex: const [
                ForexRow(
                  code: 'USD',
                  rateMicro: 83200000,
                  updatedAtMs: 1760000000000,
                ),
                ForexRow(
                  code: 'EUR',
                  rateMicro: 90500000,
                  updatedAtMs: 1760000000000,
                ),
              ],
              slabs: LegacySlabs.from(testIndiaRegime),
            ),
          }),
        );
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
        Get.offAllNamed<void>(AppRoutes.storeConfig);
        await tester.pumpAndSettle();
        await expectGolden(find.byType(PosApp), 'store_config_$mode');
      } finally {
        debugDefaultTargetPlatformOverride = null;
        restoreDefaultShadows();
      }
    }, skip: skip);
  }
}
