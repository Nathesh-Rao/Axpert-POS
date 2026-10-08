// Settings page, Settings / Profile / Shift close dialogs and the signed-out
// card across window sizes (smaller sweep). VM tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/theme/tokens/app_management_sizes.dart';
import 'package:pos_application/modules/settings/widgets/settings_content.dart';
import 'package:pos_application/modules/shift/controllers/shift_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/widgets/app_modal.dart';
import 'package:pos_application/shared/widgets/app_panel.dart';
import 'package:pos_application/shared/widgets/management_page.dart';
import 'package:pos_application/shared/widgets/modal_info_row.dart';

import '../../support/layout_matrix.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

Rect _r(WidgetTester t, Finder f) => t.getRect(f);

void main() {
  useTestApp();

  for (final w in smallWidths) {
    for (final h in smallHeights) {
      final size = Size(w, h);
      testWidgets('Settings and shift screens at ${w.toInt()} x ${h.toInt()}', (
        tester,
      ) async {
        useLogicalViewport(tester, size);
        final binding = await bootInWidgetTest(tester);
        await tester.pumpWidget(testApp(binding));
        await tester.pumpAndSettle();
        final m = AppMetrics(size);

        // ---- Settings page ----
        Get.offAllNamed<void>(AppRoutes.more);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'settings $size');
        final panel = _r(
          tester,
          find
              .descendant(
                of: find.byType(ManagementPage),
                matching: find.byType(AppPanel),
              )
              .first,
        );
        final content = _r(tester, find.byType(SettingsContent));
        expect(content.left - panel.left, closeTo(m.managementPad, 0.6));
        expect(
          content.width,
          lessThanOrEqualTo(AppManagementSizes.settingsMaxWidth + 0.5),
        );
        expect(content.right, lessThanOrEqualTo(panel.right));

        // ---- Dialogs ----
        for (final id in <String>['settings', 'profile', 'close']) {
          Get.find<OverlayController>().open(id);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$id $size');
          final card = _r(tester, find.byType(AppModal));
          expect(card.left, greaterThanOrEqualTo(-0.5), reason: '$id $size');
          expect(card.right, lessThanOrEqualTo(w + 0.5), reason: '$id $size');
          expect(card.top, greaterThanOrEqualTo(-0.5), reason: '$id $size');
          expect(card.bottom, lessThanOrEqualTo(h + 0.5), reason: '$id $size');
          // Every row label and value stay inside the card padding.
          for (final e in tester.elementList(find.byType(ModalInfoRow))) {
            final row = tester.getRect(find.byWidget(e.widget));
            expect(
              row.left,
              greaterThanOrEqualTo(card.left + m.modalPad - 0.6),
            );
            expect(row.right, lessThanOrEqualTo(card.right - m.modalPad + 0.6));
          }
          if (id == 'close') {
            expect(find.byType(ModalInfoRow), findsNWidgets(4));
          }
          if (id == 'profile') {
            expect(find.byType(ModalInfoRow), findsNWidgets(3));
          }
          Get.find<OverlayController>().close();
          await tester.pumpAndSettle();
        }

        // ---- Signed-out card ----
        Get.find<ShiftController>().closeCounter();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'signed out $size');
        final title = _r(tester, find.text('Counter closed'));
        final body = _r(
          tester,
          find.text('Your sales are saved. See you next shift.'),
        );
        final button = _r(tester, find.text('Start new shift'));
        expect(title.center.dx, closeTo(w / 2, 1), reason: 'centred $size');
        expect(body.top - title.bottom, greaterThanOrEqualTo(12.5));
        expect(button.top - body.bottom, greaterThanOrEqualTo(24.5));
        // The card keeps its 50 px padding around the widest line.
        final left = body.left < button.left ? body.left : button.left;
        expect(left, greaterThanOrEqualTo(AppManagementSizes.signCardPad));
        expect(body.right, lessThanOrEqualTo(w));
        // Everything inside the window (the card scrolls when short).
        if (h >= 600) {
          expect(button.bottom, lessThanOrEqualTo(h + 0.5), reason: '$size');
        }
        Get.find<ShiftController>().startNewShift();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 100));
      });
    }
  }
}
