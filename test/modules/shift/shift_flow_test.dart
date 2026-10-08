// Settings, Profile, shift close and the signed-out screen. VM tests.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';
import 'package:pos_application/modules/settings/widgets/settings_content.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/modules/shift/controllers/shift_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';
import 'package:pos_application/shared/controllers/shell_chrome_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/sale_fixtures.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

Future<void> _boot(WidgetTester tester, {InMemoryLocalStore? store}) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester, store: store);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
}

void _sell() {
  final now = DateTime.now();
  Get.find<SalesController>().sales.addAll(
    <dynamic>[
      testSale(number: '1', at: now, mode: 'Cash', totalMinor: 30000),
      testSale(number: '2', at: now, mode: 'Card', totalMinor: 50000),
      testSale(number: '3', at: now, mode: 'Credit', totalMinor: 10000),
      testSale(
        number: '4',
        at: now.subtract(const Duration(days: 2)),
        totalMinor: 99900,
      ),
    ].cast(),
  );
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pump(const Duration(milliseconds: 60));
}

void main() {
  useTestApp();

  testWidgets('the Settings page shows the heading and the two rows', (
    tester,
  ) async {
    await _boot(tester);
    Get.offAllNamed<void>(AppRoutes.more);
    await tester.pumpAndSettle();
    expect(find.text('MAISON GALAXY / RETAIL WORKSPACE'), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('A softer screen for evening shifts'), findsOneWidget);
    expect(find.text('Scan beep'), findsOneWidget);
    expect(find.text('Play a sound after a successful scan'), findsOneWidget);
    expect(find.byType(SettingsContent), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 60));
  });

  testWidgets('the Settings dialog has the same rows and persists them', (
    tester,
  ) async {
    final store = InMemoryLocalStore();
    await _boot(tester, store: store);
    Get.find<OverlayController>().open('settings');
    await tester.pumpAndSettle();
    expect(find.byType(SettingsContent), findsOneWidget);
    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('Scan beep'), findsOneWidget);
    expect(Get.find<SettingsController>().settings.value.beep, isTrue);
    await tester.tap(find.text('Scan beep'));
    await tester.pumpAndSettle();
    expect(Get.find<SettingsController>().settings.value.beep, isFalse);
    expect(await tester.runAsync(() => store.read(StorageKeys.beep)), isFalse);
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    expect(Get.find<SettingsController>().dark, isTrue);
    Get.find<OverlayController>().close();
    await tester.pumpAndSettle();
    await _drain(tester);
  });

  testWidgets('Profile shows the cashier, counter, shift sales and status', (
    tester,
  ) async {
    await _boot(tester);
    _sell();
    Get.find<OverlayController>().open('profile');
    await tester.pumpAndSettle();
    expect(find.text('MGTCASH3'), findsWidgets);
    expect(find.text('Cashier · MAISON GALAXY - OZONE'), findsOneWidget);
    expect(find.text('Counter'), findsOneWidget);
    expect(find.text('C3'), findsOneWidget);
    expect(find.text('Shift sales'), findsOneWidget);
    expect(find.text('₹900.00'), findsOneWidget); // today only, all modes
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Online'), findsWidgets);
    Get.find<ShellChromeController>().toggleOnline();
    await tester.pumpAndSettle();
    expect(find.text('Offline'), findsWidgets);
    Get.find<OverlayController>().close();
    await tester.pumpAndSettle();
    await _drain(tester);
  });

  testWidgets('shift close lists total, Cash, Card and bills (no Credit)', (
    tester,
  ) async {
    await _boot(tester);
    _sell();
    Get.find<OverlayController>().open('close');
    await tester.pumpAndSettle();
    expect(find.text('Close counter'), findsOneWidget);
    expect(find.text('Your shift at a glance.'), findsOneWidget);
    for (final row in <String>[
      'Total sales',
      'Cash',
      'Card',
      'Number of bills',
    ]) {
      expect(find.text(row), findsWidgets, reason: row);
    }
    expect(find.text('₹900.00'), findsOneWidget);
    expect(find.text('₹300.00'), findsOneWidget);
    expect(find.text('₹500.00'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('Credit'), findsNothing);
    expect(
      find.text('Current cart and held bills will remain saved.'),
      findsOneWidget,
    );
    expect(find.text('Confirm & close counter'), findsOneWidget);
    Get.find<OverlayController>().close();
    await tester.pumpAndSettle();
    await _drain(tester);
  });

  testWidgets('confirm shows the Counter closed card; the app is kept', (
    tester,
  ) async {
    await _boot(tester);
    final products = Get.find<ProductsController>();
    Get.find<CartActionsController>().add(products.byId(1)!);
    await tester.pump();
    final lines = Get.find<CartController>().cart.value.lines.length;
    expect(lines, 1);

    Get.find<OverlayController>().open('close');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm & close counter'));
    await tester.pumpAndSettle();
    final shift = Get.find<ShiftController>();
    expect(shift.signedOut.value, isTrue);
    expect(Get.find<OverlayController>().isOpen, isFalse);
    expect(find.text('Counter closed'), findsOneWidget);
    expect(
      find.text('Your sales are saved. See you next shift.'),
      findsOneWidget,
    );
    expect(find.text('Start new shift'), findsOneWidget);
    // The cart is untouched underneath.
    expect(Get.find<CartController>().cart.value.lines.length, 1);

    // The start button has the keyboard focus: Enter starts the shift.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(shift.signedOut.value, isFalse);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Counter closed'), findsNothing);
    expect(Get.find<CartController>().cart.value.lines.length, 1);
    expect(Get.find<SearchFieldController>().focusNode.hasFocus, isTrue);
    await _drain(tester);
  });

  testWidgets('Start new shift by tap; the signed-out state is not saved', (
    tester,
  ) async {
    final store = InMemoryLocalStore();
    await _boot(tester, store: store);
    Get.find<ShiftController>().closeCounter();
    await tester.pumpAndSettle();
    expect(find.text('Counter closed'), findsOneWidget);
    await tester.tap(find.text('Start new shift'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Counter closed'), findsNothing);
    // The flag lives in memory only (ShiftController has no store).
    expect(Get.find<ShiftController>().signedOut.value, isFalse);
    await _drain(tester);
  });

  testWidgets('F-keys still act while signed out, as in the prototype', (
    tester,
  ) async {
    await _boot(tester);
    Get.find<ShiftController>().closeCounter();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.f5);
    await tester.pump();
    // The recall dialog opened underneath (state only); the card stays on top.
    expect(Get.find<OverlayController>().modal.value, 'recall');
    expect(find.text('Counter closed'), findsOneWidget);
    // Toasts are not drawn on the card.
    Get.find<ToastController>().show('hidden');
    await tester.pump();
    expect(find.text('hidden'), findsNothing);
    Get.find<OverlayController>().close();
    await tester.pumpAndSettle();
    Get.find<ShiftController>().startNewShift();
    await tester.pumpAndSettle();
    await _drain(tester);
  });

  testWidgets('typing while signed out does not reach the hidden search', (
    tester,
  ) async {
    await _boot(tester);
    Get.find<SearchFieldController>().focus();
    await tester.pump();
    Get.find<ShiftController>().closeCounter();
    await tester.pumpAndSettle();
    expect(Get.find<SearchFieldController>().focusNode.hasFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.pump();
    expect(Get.find<SearchFieldController>().text.text, isEmpty);
    Get.find<ShiftController>().startNewShift();
    await tester.pumpAndSettle();
    await _drain(tester);
  });
}
