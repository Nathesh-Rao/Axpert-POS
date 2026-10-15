// The Store configuration page: sections, sample bill, the preset / Custom
// picker, the save confirmation, the India-label warning, the currency lock
// and the role gate (admin edits, manager views, cashier has no access).
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/features/session/presentation/controllers/active_session.dart';
import 'package:pos_application/features/store_config/data/in_memory_store_config_repository.dart';
import 'package:pos_application/features/store_config/domain/entities/store_config.dart';
import 'package:pos_application/features/store_config/domain/repositories/store_config_repository.dart';
import 'package:pos_application/features/store_config/domain/services/legacy_slabs.dart';
import 'package:pos_application/features/store_config/presentation/controllers/store_config_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/test_app.dart';
import '../../support/test_session.dart';
import '../../support/test_tax.dart';
import '../../support/viewport.dart';

StoreConfig _india({String country = 'IN', String currency = 'INR'}) =>
    StoreConfig(
      storeId: 'test-ozone',
      name: 'MAISON GALAXY - OZONE',
      countryCode: country,
      stateCode: 'KA',
      currencyCode: currency,
      forex: const [ForexRow(code: 'USD', rateMicro: 83200000)],
      slabs: LegacySlabs.from(testIndiaRegime),
    );

Future<InMemoryStoreConfigRepository> _open(
  WidgetTester tester, {
  String role = 'admin',
  bool hasSales = false,
  StoreConfig? config,
}) async {
  useReferenceViewport(tester);
  final repo = InMemoryStoreConfigRepository({
    'test-ozone': config ?? _india(),
  }, hasSales: hasSales);
  final binding = await bootInWidgetTest(tester, session: roleSession(role));
  Get.put<StoreConfigRepository>(repo);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  Get.offAllNamed<void>(AppRoutes.storeConfig);
  await tester.pumpAndSettle();
  return repo;
}

/// Lets the toasts of the test expire (their timers must not stay pending).
Future<void> _drain(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 6));

void main() {
  useTestApp();

  testWidgets('admin sees the sections and the sample bill with CGST + SGST', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('Store configuration'), findsWidgets);
    expect(find.text('Store'), findsOneWidget);
    expect(find.text('Currency'), findsWidgets);
    expect(find.text('Tax'), findsOneWidget);
    expect(find.text('Sample bill'), findsOneWidget);
    expect(find.text('Exchange rates'), findsOneWidget);
    // The default slab of the legacy India regime is the first non-zero one
    // (5%): tax 50.00 on 1,000.00 split 25.00 + 25.00.
    expect(find.text('CGST'), findsWidgets);
    expect(find.text('₹1,000.00'), findsWidgets);
    expect(find.text('₹50.00'), findsOneWidget);
    expect(find.text('₹25.00'), findsNWidgets(2));
    expect(find.text('₹1,050.00'), findsOneWidget);
    // The key hints and the actions.
    expect(find.text('Save'), findsWidgets);
    expect(find.text('Cancel'), findsWidgets);
  });

  testWidgets('the picker offers presets and a Custom entry with its field', (
    tester,
  ) async {
    await _open(tester);
    final controller = Get.find<StoreConfigController>();
    expect(controller.pickerEntries.last, StoreConfigController.customEntry);
    expect(controller.pickerEntries.first, 'GST');
    controller.addComponent(1);
    await tester.pumpAndSettle();
    final before = controller.slabs[1].components.length;
    expect(before, 3);
    controller.pickComponent(1, before - 1, StoreConfigController.customEntry);
    await tester.pumpAndSettle();
    expect(controller.slabs[1].components.last.custom, isTrue);
    expect(find.text('Custom'), findsWidgets);
    controller.slabs[1].components.last.label.text = 'Tourism levy';
    controller.slabs[1].components.last.rate.text = '2';
    controller.touch();
    await tester.pumpAndSettle();
    // 5% + 2% = 7% on 1,000.00: three lines that add up.
    expect(find.text('Total 7%'), findsOneWidget);
    expect(find.text('Tourism levy'), findsWidgets);
    expect(find.text('₹70.00'), findsOneWidget);
  });

  testWidgets('GST outside India warns but is allowed', (tester) async {
    await _open(
      tester,
      config: _india(country: 'UG', currency: 'UGX'),
    );
    final controller = Get.find<StoreConfigController>();
    final overlay = Get.find<OverlayController>();
    controller.pickComponent(0, 0, 'SGST');
    await tester.pumpAndSettle();
    expect(overlay.confirmation!.text, 'SGST is used in India. Continue?');
    expect(controller.slabs[0].components[0].label.text, 'CGST');
    overlay.accept();
    await tester.pumpAndSettle();
    expect(controller.slabs[0].components[0].label.text, 'SGST');
    // A non-Indian preset is applied at once.
    controller.pickComponent(0, 0, 'VAT');
    await tester.pumpAndSettle();
    expect(controller.slabs[0].components[0].label.text, 'VAT');
    expect(overlay.isOpen, isFalse);
  });

  testWidgets('save asks for a confirmation, then stores and applies it', (
    tester,
  ) async {
    final repo = await _open(tester);
    final controller = Get.find<StoreConfigController>();
    final session = Get.find<ActiveSession>();
    controller.name.text = 'Ozone Mart';
    controller.requestSave();
    await tester.pumpAndSettle();
    expect(find.textContaining('applies to new sales only'), findsOneWidget);
    expect(repo.saves, 0);
    Get.find<OverlayController>().accept();
    await tester.pumpAndSettle();
    expect(repo.saves, 1);
    expect(repo.configs['test-ozone']!.name, 'Ozone Mart');
    expect(session.store.value!.name, 'Ozone Mart');
    await _drain(tester);
  });

  testWidgets('problems are listed and nothing is saved', (tester) async {
    final repo = await _open(tester);
    final controller = Get.find<StoreConfigController>();
    controller.slabs[1].components[0].rate.text = '150';
    controller.touch();
    controller.requestSave();
    await tester.pumpAndSettle();
    expect(repo.saves, 0);
    expect(controller.issues, isNotEmpty);
    expect(find.textContaining('enter a rate from 0 to 100'), findsOneWidget);
    expect(Get.find<OverlayController>().isOpen, isFalse);
    await _drain(tester);
  });

  testWidgets('a store with sales keeps its currency', (tester) async {
    await _open(tester, hasSales: true);
    final controller = Get.find<StoreConfigController>();
    controller.setCurrency('USD');
    await tester.pumpAndSettle();
    expect(controller.currency.value, 'INR');
    expect(
      Get.find<ToastController>().toasts.last.text,
      contains('currency can no longer be changed'),
    );
    expect(
      find.textContaining('currency can no longer be changed'),
      findsWidgets,
    );
    await _drain(tester);
  });

  testWidgets('without sales the currency follows the country default', (
    tester,
  ) async {
    await _open(tester);
    final controller = Get.find<StoreConfigController>();
    controller.setCountry('UG');
    await tester.pumpAndSettle();
    expect(controller.currency.value, 'UGX');
    // A currency set by hand stays when the country changes again.
    controller.setCurrency('USD');
    controller.setCountry('KE');
    expect(controller.currency.value, 'USD');
    expect(controller.currencyMismatch, isTrue);
    await _drain(tester);
  });

  testWidgets('a manager can view but not change', (tester) async {
    final repo = await _open(tester, role: 'manager');
    final controller = Get.find<StoreConfigController>();
    expect(controller.canView, isTrue);
    expect(controller.canEdit, isFalse);
    expect(find.text('Sample bill'), findsOneWidget);
    expect(find.textContaining('View only'), findsOneWidget);
    controller.name.text = 'Hacked';
    controller.requestSave();
    controller.addSlab();
    controller.removeSlab(0);
    await tester.pumpAndSettle();
    expect(repo.saves, 0);
    expect(controller.slabs.length, 4);
    expect(Get.find<OverlayController>().isOpen, isFalse);
    expect(
      Get.find<ToastController>().toasts.last.text,
      'Only an admin can change the store configuration',
    );
    await _drain(tester);
  });

  testWidgets('a cashier has no access and nothing is loaded', (tester) async {
    await _open(tester, role: 'cashier');
    final controller = Get.find<StoreConfigController>();
    expect(controller.canView, isFalse);
    expect(find.textContaining('do not have access'), findsOneWidget);
    expect(find.text('Sample bill'), findsNothing);
    expect(controller.slabs, isEmpty);
    controller.requestSave();
    controller.addSlab();
    expect(controller.slabs, isEmpty);
    await _drain(tester);
  });

  testWidgets('Esc leaves the page without saving', (tester) async {
    final repo = await _open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.more);
    expect(repo.saves, 0);
  });
}
