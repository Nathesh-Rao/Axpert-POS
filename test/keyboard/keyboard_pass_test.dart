// S6 keyboard and focus pass over every screen and dialog: Tab order follows
// the prototype's DOM order, Shift+Tab reverses it, Esc closes every dialog
// and returns focus to the search, Ctrl and Cmd both focus the search, Enter
// activates buttons. VM tests.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';

import '../support/focus_probe.dart';
import '../support/sale_fixtures.dart';
import '../support/test_app.dart';
import '../support/viewport.dart';

const List<String> _sidebar = <String>[
  'POS',
  'Products',
  'Customers',
  'Sales',
  'Returns',
  'Reports',
  'More',
];

Future<void> _boot(WidgetTester tester, String route) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  Get.find<SalesController>().sales.add(
    testSale(number: 'AX000001', at: DateTime(2026, 10, 8)),
  );
  Get.offAllNamed<void>(route);
  await tester.pumpAndSettle();
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  useTestApp();

  // The first stop after the sidebar, per page (the page's own control).
  const firstOfPage = <String, String>{
    AppRoutes.products: 'catalog-search',
    AppRoutes.customers: 'Add Customer',
    AppRoutes.sales: 'catalog-search',
    AppRoutes.returns: 'catalog-search',
  };

  for (final route in <String>[
    AppRoutes.pos,
    AppRoutes.products,
    AppRoutes.customers,
    AppRoutes.sales,
    AppRoutes.returns,
    AppRoutes.reports,
    AppRoutes.more,
  ]) {
    testWidgets('Tab order on $route: top bar, sidebar, page, summary', (
      tester,
    ) async {
      await _boot(tester, route);
      final stops = await walkTab(tester, 45);
      // The top bar comes first.
      expect(stops.first, 'MAISON GALAXY - OZONE');
      expect(stops[1], 'global-search');
      // The seven sidebar buttons are one consecutive block, in order.
      final first = stops.indexOf('POS');
      expect(first, greaterThan(1), reason: route);
      expect(stops.sublist(first, first + 7), _sidebar, reason: route);
      // The page's own controls follow the sidebar, not interleave with it.
      final expected = firstOfPage[route];
      if (expected != null) {
        expect(stops[first + 7], expected, reason: route);
      }
      final wrap = stops.indexOf('MAISON GALAXY - OZONE', 1);
      final cycle = wrap < 0 ? stops : stops.sublist(0, wrap);
      expect(
        cycle.sublist(first + 7).where(_sidebar.contains),
        isEmpty,
        reason: 'no sidebar button after the page starts ($route)',
      );
      await _drain(tester);
    });
  }

  testWidgets('Shift+Tab walks the same order backwards', (tester) async {
    await _boot(tester, AppRoutes.customers);
    final forward = await walkTab(tester, 12);
    final back = await walkTab(tester, 11, reverse: true);
    expect(back, forward.sublist(0, 11).reversed.toList());
    await _drain(tester);
  });

  testWidgets('Settings rows are one Tab stop each (the checkbox)', (
    tester,
  ) async {
    await _boot(tester, AppRoutes.more);
    final stops = await walkTab(tester, 18);
    final firstSummary = stops.indexOf('rate');
    final afterSidebar = stops.indexOf('More') + 1;
    // Two settings rows, two stops, then the Bill Summary.
    expect(
      stops.sublist(afterSidebar, firstSummary).where((s) => s.isEmpty).length,
      2, // the two checkboxes
    );
    await _drain(tester);
  });

  testWidgets('Ctrl+K and Cmd+K focus the search on every page', (
    tester,
  ) async {
    for (final route in <String>[
      AppRoutes.products,
      AppRoutes.returns,
      AppRoutes.more,
    ]) {
      for (final modifier in <LogicalKeyboardKey>[
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.metaLeft,
      ]) {
        await _boot(tester, route);
        await tester.sendKeyDownEvent(modifier);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
        await tester.sendKeyUpEvent(modifier);
        await tester.pump();
        expect(
          Get.find<SearchFieldController>().focusNode.hasFocus,
          isTrue,
          reason: '$route $modifier',
        );
        await _drain(tester);
      }
    }
  });

  testWidgets('F6 opens the discount drawer from a page input', (tester) async {
    await _boot(tester, AppRoutes.returns);
    await walkTab(tester, 10);
    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.pumpAndSettle();
    expect(Get.find<OverlayController>().modal.value, 'discount');
    Get.find<OverlayController>().close();
    await tester.pumpAndSettle();
    await _drain(tester);
  });

  testWidgets('Enter on a sidebar button navigates', (tester) async {
    await _boot(tester, AppRoutes.reports);
    final stops = await walkTab(tester, 12);
    expect(stops, contains('Sales'));
    // Focus back on "Sales": step until the focus is there, then Enter.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    var guard = 0;
    while (guard++ < 30) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      if (describeFocus() == 'Sales') break;
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.sales);
    await _drain(tester);
  });

  // Every dialog: Esc closes it and the search gets the focus back.
  final dialogs = <String, Object?>{
    'settings': null,
    'profile': null,
    'close': null,
    'shortcuts': null,
    'scan': null,
    'priceCheck': null,
    'customers': null,
    'addCustomer': null,
    'recall': null,
    'discount': null,
    'counter': null,
    'note': null,
    'reprint': null,
    'receipt': 'sale',
  };
  for (final entry in dialogs.entries) {
    testWidgets('Esc closes the ${entry.key} dialog and refocuses search', (
      tester,
    ) async {
      await _boot(tester, AppRoutes.pos);
      final sale = testSale(number: 'AX000009', at: DateTime(2026, 10, 8));
      Get.find<OverlayController>().open(
        entry.key,
        payload: entry.value == null ? null : sale,
      );
      await tester.pumpAndSettle();
      expect(Get.find<OverlayController>().isOpen, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(Get.find<OverlayController>().isOpen, isFalse);
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        Get.find<SearchFieldController>().focusNode.hasFocus,
        isTrue,
        reason: entry.key,
      );
      await _drain(tester);
    });
  }

  testWidgets('the receipt buttons are Tab stops and Enter works', (
    tester,
  ) async {
    await _boot(tester, AppRoutes.pos);
    Get.find<OverlayController>().open(
      'receipt',
      payload: testSale(number: 'AX000009', at: DateTime(2026, 10, 8)),
    );
    await tester.pumpAndSettle();
    final stops = await walkTab(tester, 6);
    expect(
      stops,
      containsAll(<String>['Print', 'Email', 'WhatsApp', 'New Sale']),
    );
    // Walk to "New Sale" and press Enter: the dialog closes.
    var guard = 0;
    while (describeFocus() != 'New Sale' && guard++ < 10) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(Get.find<OverlayController>().isOpen, isFalse);
    await _drain(tester);
  });

  testWidgets('Tab stays inside an open dialog (deviation, KG-168)', (
    tester,
  ) async {
    await _boot(tester, AppRoutes.pos);
    Get.find<OverlayController>().open('close');
    await tester.pumpAndSettle();
    final stops = await walkTab(tester, 8);
    expect(
      stops.toSet().difference(<String>{'', 'Confirm & close counter'}),
      isEmpty,
    );
    Get.find<OverlayController>().close();
    await tester.pumpAndSettle();
    await _drain(tester);
  });
}
