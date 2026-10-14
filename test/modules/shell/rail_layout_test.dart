// The side rail (DEC-142): width, item height and gap equal the metrics at the
// three reference windows, light and dark, every item visible, "More" at the
// bottom, nothing clipped or overflowing.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/modules/shell/widgets/sidebar.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

const _sizes = <Size>[Size(950, 733), Size(1280, 720), Size(1868, 1035)];

void main() {
  useTestApp();
  for (final size in _sizes) {
    for (final dark in <bool>[false, true]) {
      testWidgets('rail at ${size.width.toInt()}x${size.height.toInt()} '
          '${dark ? 'dark' : 'light'}', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          useLogicalViewport(tester, size);
          final binding = await bootInWidgetTest(tester);
          if (dark) {
            await tester.runAsync(
              () => Get.find<SettingsController>().setDark(true),
            );
          }
          await tester.pumpWidget(testApp(binding));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final m = AppMetrics(size, touch: false);
          final rail = tester.getRect(find.byType(Sidebar));
          expect(rail.width, closeTo(m.sidebarWidth, 0.01));
          expect(m.sidebarWidth, size.width <= 1280 ? 56 : 68);

          final items = <Rect>[
            for (final e in find.byType(SidebarButton).evaluate())
              tester.getRect(find.byWidget(e.widget)),
          ];
          expect(items, hasLength(7));
          for (final r in items) {
            expect(r.height, closeTo(m.sidebarButtonHeight, 0.01));
            // Inside the rail with its padding, fully on screen.
            expect(r.left, greaterThanOrEqualTo(rail.left));
            expect(r.right, lessThanOrEqualTo(rail.right));
            expect(r.bottom, lessThanOrEqualTo(size.height));
            expect(r.top, greaterThanOrEqualTo(0));
          }
          // Gaps between the first six; "More" is pinned to the bottom.
          for (var i = 1; i < 6; i++) {
            expect(
              items[i].top - items[i - 1].bottom,
              closeTo(m.sidebarGap, 0.01),
              reason: 'gap before item $i',
            );
          }
          expect(items[6].top, greaterThan(items[5].bottom));
          expect(items[6].bottom, closeTo(rail.bottom - 4, 0.5));
          // Labels are whole: no ellipsis, none wider than its item.
          for (final label in <String>[
            'POS',
            'Products',
            'Customers',
            'Sales',
            'Returns',
            'Reports',
            'More',
          ]) {
            final text = find.descendant(
              of: find.byType(Sidebar),
              matching: find.text(label),
            );
            expect(text, findsOneWidget, reason: label);
            final w = tester.widget<Text>(text);
            expect(w.overflow, isNot(TextOverflow.ellipsis));
            expect(
              tester.getRect(text).width,
              lessThanOrEqualTo(rail.width - 2),
              reason: label,
            );
          }
          Get.find<ToastController>().toasts.clear();
          await tester.pump(const Duration(seconds: 6));
          await tester.pumpAndSettle();
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }
}
