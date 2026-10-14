// The side rail card: icon-only, width and item size equal the rail tokens at
// the three reference windows, light and dark, every item visible, a divider
// before "More", names in tooltips and semantics, nothing clipped. Touch keeps
// the labelled strip.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/theme/tokens/app_rail_sizes.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/modules/shell/widgets/rail_item.dart';
import 'package:pos_application/modules/shell/widgets/sidebar.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/rail_finders.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

const _sizes = <Size>[Size(950, 733), Size(1280, 720), Size(1868, 1035)];
const _names = <String>[
  'POS',
  'Products',
  'Customers',
  'Sales',
  'Returns',
  'Reports',
  'More',
];

void main() {
  useTestApp();
  test('narrow rail is not wider than the normal rail', () {
    expect(
      AppRailSizes.narrow.width,
      lessThanOrEqualTo(AppRailSizes.normal.width),
    );
    expect(
      AppRailSizes.narrow.item,
      lessThanOrEqualTo(AppRailSizes.normal.item),
    );
    for (final s in <AppRailSizes>[AppRailSizes.normal, AppRailSizes.narrow]) {
      expect(s.item + 2 * s.padX, lessThanOrEqualTo(s.width));
    }
  });

  for (final size in _sizes) {
    for (final dark in <bool>[false, true]) {
      testWidgets('rail at ${size.width.toInt()}x${size.height.toInt()} '
          '${dark ? 'dark' : 'light'}', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        final semantics = tester.ensureSemantics();
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
          final sizes = m.railSizes;
          expect(sizes.width, size.width <= 1280 ? 48 : 56);
          final rail = tester.getRect(find.byType(Sidebar));
          expect(rail.width, closeTo(m.sidebarWidth, 0.01));
          expect(rail.left, closeTo(m.railMargin, 0.01));

          final items = <Rect>[
            for (final e in find.byType(RailItem).evaluate())
              tester.getRect(find.byWidget(e.widget)),
          ];
          expect(items, hasLength(7));
          for (final r in items) {
            expect(r.width, closeTo(sizes.item, 0.01));
            expect(r.height, closeTo(sizes.item, 0.01));
            expect(r.center.dx, closeTo(rail.center.dx, 0.01));
            expect(r.left, greaterThanOrEqualTo(rail.left));
            expect(r.right, lessThanOrEqualTo(rail.right));
            expect(r.top, greaterThanOrEqualTo(rail.top));
            expect(r.bottom, lessThanOrEqualTo(rail.bottom));
          }
          // Even gaps inside the primary group; the divider space before More.
          for (var i = 1; i < 6; i++) {
            expect(
              items[i].top - items[i - 1].bottom,
              closeTo(AppRailSizes.itemGap, 0.01),
              reason: 'gap before item $i',
            );
          }
          expect(
            items[6].top - items[5].bottom,
            closeTo(
              2 * AppRailSizes.dividerMargin + AppRailSizes.dividerThickness,
              0.01,
            ),
          );
          // Icon-only: no names as text, names in tooltips.
          for (final name in _names) {
            expect(
              find.descendant(
                of: find.byType(Sidebar),
                matching: find.text(name),
              ),
              findsNothing,
              reason: 'no label text for $name',
            );
            expect(sidebarItem(name), findsOneWidget, reason: name);
          }
          // The selected item is exposed through semantics.
          expect(
            tester.getSemantics(sidebarItem('POS')),
            matchesSemantics(
              label: 'POS',
              isButton: true,
              isSelected: true,
              hasSelectedState: true,
              hasTapAction: true,
              isFocusable: true,
              hasFocusAction: true,
              hasEnabledState: false,
            ),
          );
          Get.find<ToastController>().toasts.clear();
          await tester.pump(const Duration(seconds: 6));
          await tester.pumpAndSettle();
        } finally {
          semantics.dispose();
          debugDefaultTargetPlatformOverride = null;
        }
      });
    }
  }

  testWidgets('touch keeps the labelled rail', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      useLogicalViewport(tester, const Size(1280, 720));
      final binding = await bootInWidgetTest(tester);
      await tester.pumpWidget(testApp(binding));
      await tester.pumpAndSettle();
      expect(find.byType(SidebarButton), findsNWidgets(7));
      expect(find.byType(RailItem), findsNothing);
      expect(
        tester.getRect(find.byType(Sidebar)).width,
        closeTo(AppMetrics(const Size(1280, 720)).sidebarWidth, 0.01),
      );
      for (final name in _names) {
        expect(
          find.descendant(of: find.byType(Sidebar), matching: find.text(name)),
          findsOneWidget,
          reason: name,
        );
      }
      Get.find<ToastController>().toasts.clear();
      await tester.pump(const Duration(seconds: 6));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('hover opens the tooltip right of the item, leaving hides it', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      const size = Size(1280, 720);
      useLogicalViewport(tester, size);
      final binding = await bootInWidgetTest(tester);
      await tester.pumpWidget(testApp(binding));
      await tester.pumpAndSettle();
      final tip = find.text('Products');
      expect(tip, findsNothing);
      final item = tester.getRect(sidebarItem('Products'));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(item.center);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tip, findsNothing, reason: 'short delay first');
      await tester.pump(AppRailSizes.tooltipDelay);
      expect(tip, findsOneWidget);
      final bubble = tester.getRect(
        find.ancestor(of: tip, matching: find.byType(DecoratedBox)).first,
      );
      expect(bubble.left, greaterThanOrEqualTo(item.right));
      expect(bubble.left, closeTo(item.right + AppRailSizes.tooltipGap, 0.5));
      expect(bubble.center.dy, closeTo(item.center.dy, 0.5));
      expect(bubble.left, greaterThanOrEqualTo(0));
      expect(bubble.top, greaterThanOrEqualTo(0));
      expect(bubble.right, lessThanOrEqualTo(size.width));
      expect(bubble.bottom, lessThanOrEqualTo(size.height));
      // The next item stays uncovered.
      expect(
        bubble.overlaps(tester.getRect(sidebarItem('Customers'))),
        isFalse,
      );
      await mouse.moveTo(const Offset(600, 400));
      await tester.pump();
      expect(tip, findsNothing);
      await mouse.removePointer();
      Get.find<ToastController>().toasts.clear();
      await tester.pump(const Duration(seconds: 6));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'keyboard focus shows the tooltip, Esc hides it, Enter activates',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        useLogicalViewport(tester, const Size(1280, 720));
        final binding = await bootInWidgetTest(tester);
        await tester.pumpWidget(testApp(binding));
        await tester.pumpAndSettle();
        // Tab to the rail marks keyboard (traditional) focus mode.
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.alwaysTraditional;
        Focus.of(
          tester.element(
            find
                .descendant(
                  of: sidebarItem('Customers'),
                  matching: find.byType(GestureDetector),
                )
                .first,
          ),
        ).requestFocus();
        await tester.pump();
        expect(find.text('Customers'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        expect(find.text('Customers'), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(Get.currentRoute, AppRoutes.customers);
        Get.find<ToastController>().toasts.clear();
        await tester.pump(const Duration(seconds: 6));
      } finally {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}
