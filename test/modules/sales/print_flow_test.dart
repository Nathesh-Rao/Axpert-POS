// Print from the receipt dialog: the completed sale, Reprint of a sale and Print
// draft each hand the right document to the PrintService exactly once; an
// unsupported or failed print shows a toast and never throws.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/services/print/print_service_factory.dart';
import 'package:pos_application/core/services/print/unsupported_print_service.dart';
import 'package:pos_application/core/services/print_service.dart';
import 'package:pos_application/core/services/receipt_share_service.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/features/session/presentation/controllers/active_session.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/order_menu_controller.dart';
import 'package:pos_application/modules/pos/controllers/payment_controller.dart';
import 'package:pos_application/modules/pos/models/payment_state.dart';
import 'package:pos_application/modules/sales/controllers/receipt_controller.dart';
import 'package:pos_application/modules/sales/widgets/receipt_dialog.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

Future<void> _boot(WidgetTester tester, {PrintService? printer}) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester);
  if (printer != null) {
    Get.delete<ReceiptController>(force: true);
    Get.put<ReceiptController>(
      ReceiptController(
        overlay: Get.find(),
        toasts: Get.find(),
        printer: printer,
        sharing: RecordingReceiptShareService(),
        settings: Get.find(),
        session: Get.find<ActiveSession>(),
      ),
      permanent: true,
    );
  }
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
}

Future<void> _add(WidgetTester tester, int id) async {
  Get.find<CartActionsController>().add(
    Get.find<ProductsController>().byId(id)!,
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _payCash(WidgetTester tester) async {
  await _add(tester, 5);
  final pay = Get.find<PaymentController>();
  pay.payment(PaymentMode.cash);
  await tester.pump();
  pay.tendered.text = '50';
  pay.completeCash();
  await tester.pumpAndSettle();
}

Future<void> _tapPrint(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(ReceiptDialog),
      matching: find.text('Print'),
    ),
  );
  await tester.pump();
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

List<String> _toasts() =>
    Get.find<ToastController>().toasts.map((t) => t.text).toList();

RecordingPrintService get _printer =>
    Get.find<PrintService>() as RecordingPrintService;

void main() {
  useTestApp();

  testWidgets('Print after a sale prints that sale once on 80 mm paper', (
    tester,
  ) async {
    await _boot(tester);
    await _payCash(tester);
    await _tapPrint(tester);
    expect(_printer.printed, hasLength(1));
    expect(_printer.printed.single.number, 'AX000001');
    expect(_printer.paperMm, <int>[80]);
    expect(_toasts().where((t) => t.contains('print')), isEmpty);
    await _drain(tester);
  });

  testWidgets('Reprint: pick a sale, Print sends that sale once', (
    tester,
  ) async {
    await _boot(tester);
    await _payCash(tester);
    Get.find<OverlayController>().close();
    await tester.pumpAndSettle();
    Get.find<OverlayController>().open('reprint');
    await tester.pumpAndSettle();
    // Reprint itself prints nothing: it only lists the sales.
    expect(_printer.printed, isEmpty);
    await tester.tap(find.text('AX000001 · Walk-in Customer'));
    await tester.pumpAndSettle();
    await _tapPrint(tester);
    expect(_printer.printed, hasLength(1));
    expect(_printer.printed.single.number, 'AX000001');
    await _drain(tester);
  });

  testWidgets('Print draft: the unpaid draft is printed once', (tester) async {
    await _boot(tester);
    await _add(tester, 5);
    Get.find<OrderMenuController>().printDraft();
    await tester.pumpAndSettle();
    expect(
      _printer.printed,
      isEmpty,
      reason: 'opening the draft prints nothing',
    );
    await _tapPrint(tester);
    expect(_printer.printed, hasLength(1));
    expect(_printer.printed.single.number, 'DRAFT');
    expect(_printer.printed.single.mode, 'Unpaid');
    await _drain(tester);
  });

  testWidgets('the print_paper_mm setting is the paper width', (tester) async {
    await _boot(tester);
    await tester.runAsync(
      () => Get.find<SettingsController>().setPrintPaperMm(58),
    );
    await _payCash(tester);
    await _tapPrint(tester);
    expect(_printer.paperMm, <int>[58]);
    await _drain(tester);
  });

  testWidgets('an unsupported platform shows a toast and does not throw', (
    tester,
  ) async {
    final printer = RecordingPrintService(supported: false);
    await _boot(tester, printer: printer);
    await _payCash(tester);
    Get.find<ToastController>().toasts.clear();
    await _tapPrint(tester);
    await tester.pump();
    expect(printer.printed, isEmpty);
    expect(_toasts(), <String>['Printing is not available on this platform']);
    await _drain(tester);
  });

  testWidgets('a failed print shows a toast and does not throw', (
    tester,
  ) async {
    final printer = RecordingPrintService(outcome: PrintOutcome.failed);
    await _boot(tester, printer: printer);
    await _payCash(tester);
    Get.find<ToastController>().toasts.clear();
    await _tapPrint(tester);
    await tester.pump();
    expect(printer.printed, hasLength(1));
    expect(_toasts(), <String>['Could not print the receipt']);
    await _drain(tester);
  });

  test('the fallback service reports unsupported and never throws', () async {
    const service = UnsupportedPrintService();
    expect(service.supported, isFalse);
    final printer = RecordingPrintService();
    expect(printer.supported, isTrue);
    expect(createPrintService(), isA<PrintService>());
  });
}
