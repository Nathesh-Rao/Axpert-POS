import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/constants/app_strings.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/modules/shell/widgets/sidebar.dart';
import 'package:pos_application/modules/shell/widgets/top_bar.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/page_filter_controller.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';
import 'package:pos_application/shared/controllers/shell_chrome_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/viewport.dart';
import '../../support/test_app.dart';

Future<void> _boot(WidgetTester tester) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
}

void main() {
  useTestApp();

  test('shortcut label per platform', () {
    final strings = AppStrings.current;
    expect(searchShortcutLabel(strings, TargetPlatform.macOS), '⌘K');
    expect(searchShortcutLabel(strings, TargetPlatform.windows), 'Ctrl+K');
    expect(searchShortcutLabel(strings, TargetPlatform.linux), 'Ctrl+K');
    expect(searchShortcutLabel(strings, TargetPlatform.android), 'Ctrl+K');
  });

  testWidgets('top bar shows the prototype texts', (tester) async {
    await _boot(tester);
    for (final text in <String>[
      'Axpert POS',
      'MAISON GALAXY - OZONE',
      'Online',
      'MGTCASH3',
      'Cashier',
      '3',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('Scan barcode or search product...'), findsOneWidget);
    for (final label in <String>[
      'POS',
      'Products',
      'Customers',
      'Sales',
      'Returns',
      'Reports',
      'More',
    ]) {
      expect(
        find.descendant(of: find.byType(Sidebar), matching: find.text(label)),
        findsOneWidget,
        reason: label,
      );
    }
  });

  testWidgets('online chip toggles and bell clears the badge', (tester) async {
    await _boot(tester);
    final chrome = Get.find<ShellChromeController>();
    await tester.tap(find.text('Online'));
    await tester.pump();
    expect(chrome.online.value, isFalse);
    expect(find.text('Offline'), findsOneWidget);

    expect(chrome.unread.value, isTrue);
    chrome.toggleNotifications();
    await tester.pumpAndSettle();
    expect(chrome.unread.value, isFalse);
    expect(find.text('3'), findsNothing);
    expect(find.text('🟠 Paper Boat stock is running low'), findsOneWidget);
    expect(find.text('🔵 0 held bills waiting'), findsOneWidget);
    chrome.toggleNotifications();
    await tester.pumpAndSettle();
    expect(find.text('🟠 Paper Boat stock is running low'), findsNothing);
  });

  testWidgets('user menu opens, items open the overlay controller', (
    tester,
  ) async {
    await _boot(tester);
    final chrome = Get.find<ShellChromeController>();
    chrome.toggleUserMenu();
    await tester.pumpAndSettle();
    for (final label in <String>[
      'Profile',
      'Settings',
      'Shortcuts',
      'Logout',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await tester.tap(find.text('Shortcuts'));
    await tester.pump();
    expect(Get.find<OverlayController>().modal.value, 'shortcuts');
    expect(chrome.menu.value, ShellMenu.none);
  });

  testWidgets('store select persists, toasts and refocuses', (tester) async {
    await _boot(tester);
    await tester.tap(find.text('MAISON GALAXY - OZONE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('MAISON GALAXY - MARINA'));
    await tester.pumpAndSettle();
    expect(
      Get.find<SettingsController>().settings.value.store,
      'MAISON GALAXY - MARINA',
    );
    expect(Get.find<ToastController>().toasts.single.text, 'Store switched');
    await tester.pump(const Duration(milliseconds: 60));
    expect(Get.find<SearchFieldController>().focusNode.hasFocus, isTrue);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('sidebar marks the active route and navigates', (tester) async {
    await _boot(tester);
    expect(tester.widget<Sidebar>(find.byType(Sidebar)).current, AppPage.pos);
    Get.find<PageFilterController>().set('abc');
    await tester.tap(
      find.descendant(
        of: find.byType(Sidebar),
        matching: find.text('Customers'),
      ),
    );
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.customers);
    expect(
      tester.widget<Sidebar>(find.byType(Sidebar)).current,
      AppPage.customers,
    );
    expect(Get.find<PageFilterController>().filter.value, '');
    await tester.pump(const Duration(milliseconds: 60));
    expect(Get.find<SearchFieldController>().focusNode.hasFocus, isTrue);
  });

  testWidgets('search text and focus survive navigation', (tester) async {
    await _boot(tester);
    final search = Get.find<SearchFieldController>();
    await tester.enterText(find.byType(TextField).first, 'cola');
    for (final label in <String>['Products', 'Sales', 'More', 'POS']) {
      await tester.tap(
        find.descendant(of: find.byType(Sidebar), matching: find.text(label)),
      );
      await tester.pumpAndSettle();
      expect(search.text.text, 'cola', reason: label);
    }
  });
}
