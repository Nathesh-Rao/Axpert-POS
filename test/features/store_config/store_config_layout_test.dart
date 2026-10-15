// The Store configuration page across window sizes (smaller sweep: widths
// 900, 1100, 1280, 1500, 1900 x heights 600, 733, 900, 1000): no overflow
// (any RenderFlex overflow fails the test), the cards stay inside the panel
// and the Save action can be scrolled into view. VM tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/features/store_config/data/in_memory_store_config_repository.dart';
import 'package:pos_application/features/store_config/domain/entities/store_config.dart';
import 'package:pos_application/features/store_config/domain/repositories/store_config_repository.dart';
import 'package:pos_application/features/store_config/domain/services/legacy_slabs.dart';
import 'package:pos_application/features/store_config/presentation/controllers/store_config_controller.dart';
import 'package:pos_application/shared/widgets/app_panel.dart';
import 'package:pos_application/shared/widgets/management_page.dart';

import '../../support/layout_matrix.dart';
import '../../support/test_app.dart';
import '../../support/test_session.dart';
import '../../support/test_tax.dart';
import '../../support/viewport.dart';

void main() {
  useTestApp();

  for (final w in smallWidths) {
    for (final h in smallHeights) {
      testWidgets('store configuration at $w x $h', (tester) async {
        useLogicalViewport(tester, Size(w, h));
        final binding = await bootInWidgetTest(
          tester,
          session: roleSession('admin'),
        );
        Get.put<StoreConfigRepository>(
          InMemoryStoreConfigRepository({
            'test-ozone': StoreConfig(
              storeId: 'test-ozone',
              name: 'MAISON GALAXY - OZONE',
              countryCode: 'IN',
              stateCode: '',
              currencyCode: 'INR',
              forex: const [
                ForexRow(code: 'USD', rateMicro: 83200000),
                ForexRow(code: 'EUR', rateMicro: 90500000),
              ],
              slabs: LegacySlabs.from(testIndiaRegime),
            ),
          }),
        );
        await tester.pumpWidget(testApp(binding));
        await tester.pumpAndSettle();
        Get.offAllNamed<void>(AppRoutes.storeConfig);
        await tester.pumpAndSettle();
        // A three component slab with a long custom label.
        final controller = Get.find<StoreConfigController>();
        controller.addComponent(3);
        controller.pickComponent(3, 2, StoreConfigController.customEntry);
        controller.slabs[3].components[2].label.text =
            'Municipal environment levy and tourism contribution';
        controller.slabs[3].components[2].rate.text = '1';
        controller.touch();
        await tester.pumpAndSettle();

        final panel = tester.getRect(
          find
              .descendant(
                of: find.byType(ManagementPage),
                matching: find.byType(AppPanel),
              )
              .first,
        );
        expect(panel.right, lessThanOrEqualTo(w), reason: 'panel at $w x $h');
        for (final title in <String>[
          'Store',
          'Tax',
          'Sample bill',
          'Exchange rates',
        ]) {
          final r = tester.getRect(find.text(title).first);
          expect(r.left, greaterThanOrEqualTo(panel.left), reason: title);
          expect(r.right, lessThanOrEqualTo(panel.right), reason: title);
        }
        // The page scrolls: the actions can be brought into view.
        await tester.ensureVisible(find.text('Save').last);
        await tester.pumpAndSettle();
        final save = tester.getRect(find.text('Save').last);
        expect(save.bottom, lessThanOrEqualTo(h), reason: 'Save at $w x $h');
      });
    }
  }
}
