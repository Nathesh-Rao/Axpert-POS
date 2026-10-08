// Receipt, Reprint, Rename counter, Add note, Print draft and the shortcuts
// dialog end to end. Runs on VM and Chrome.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/services/print_service.dart';
import 'package:pos_application/core/services/receipt_share_service.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/order_menu_controller.dart';
import 'package:pos_application/modules/pos/controllers/payment_controller.dart';
import 'package:pos_application/modules/pos/controllers/text_dialog_controller.dart';
import 'package:pos_application/modules/pos/models/payment_state.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/modules/sales/controllers/receipt_controller.dart';
import 'package:pos_application/modules/sales/widgets/receipt_dialog.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

Future<void> _boot(WidgetTester tester) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester);
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

Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

Finder _in(Type dialog, String text) =>
    find.descendant(of: find.byType(dialog), matching: find.text(text));

Finder _field(TextEditingController c) =>
    find.byWidgetPredicate((w) => w is TextField && w.controller == c);

List<String> _toasts() =>
    Get.find<ToastController>().toasts.map((t) => t.text).toList();

/// Pays one Lays Classic in cash and returns with the receipt open.
Future<void> _payCash(WidgetTester tester) async {
  await _add(tester, 5);
  final pay = Get.find<PaymentController>();
  pay.payment(PaymentMode.cash);
  await tester.pump();
  pay.tendered.text = '50';
  pay.completeCash();
  await tester.pumpAndSettle();
}

void main() {
  useTestApp();

  testWidgets('paying shows the receipt of that sale', (tester) async {
    await _boot(tester);
    await _payCash(tester);
    expect(Get.find<OverlayController>().modal.value, 'receipt');
    expect(_in(ReceiptDialog, 'AXPERT POS'), findsOneWidget);
    expect(_in(ReceiptDialog, 'Retail tax invoice'), findsOneWidget);
    expect(_in(ReceiptDialog, 'Bill: AX000001'), findsOneWidget);
    expect(_in(ReceiptDialog, 'Cashier: MGTCASH3'), findsOneWidget);
    expect(_in(ReceiptDialog, 'Customer: Walk-in Customer'), findsOneWidget);
    expect(_in(ReceiptDialog, 'Lays Classic 52g'), findsOneWidget);
    expect(_in(ReceiptDialog, '1.000'), findsOneWidget);
    // Subtotal, Total and the line total are 20.00 / 21.00.
    expect(_in(ReceiptDialog, '₹20.00'), findsNWidgets(2));
    expect(_in(ReceiptDialog, '₹21.00'), findsOneWidget);
    expect(_in(ReceiptDialog, '₹1.00'), findsOneWidget); // GST
    expect(_in(ReceiptDialog, 'Cash'), findsOneWidget);
    expect(_in(ReceiptDialog, '₹29.00'), findsOneWidget); // change
    expect(_in(ReceiptDialog, 'Thank you for shopping with us!'), findsOne);
    await _drain(tester);
  });

  testWidgets('Print, Email and WhatsApp use the services; New Sale closes', (
    tester,
  ) async {
    await _boot(tester);
    await _payCash(tester);
    Get.find<ToastController>().toasts.clear();
    await tester.tap(_in(ReceiptDialog, 'Print'));
    await tester.pump();
    final printer = Get.find<PrintService>() as RecordingPrintService;
    expect(printer.printed, hasLength(1));
    expect(printer.printed.single.number, 'AX000001');
    expect(_toasts(), isEmpty, reason: 'React shows the browser print dialog');

    await tester.tap(_in(ReceiptDialog, 'Email'));
    await tester.pump();
    await tester.tap(_in(ReceiptDialog, 'WhatsApp'));
    await tester.pump();
    final share =
        Get.find<ReceiptShareService>() as RecordingReceiptShareService;
    expect(share.emailed, hasLength(1));
    expect(share.whatsApped, hasLength(1));
    expect(_toasts(), <String>[
      'Receipt email sent (demo)',
      'Receipt shared on WhatsApp (demo)',
    ]);

    await tester.tap(_in(ReceiptDialog, 'New Sale'));
    await tester.pumpAndSettle();
    expect(Get.find<OverlayController>().isOpen, isFalse);
    await tester.pump(const Duration(milliseconds: 100));
    expect(Get.find<SearchFieldController>().focusNode.hasFocus, isTrue);
    expect(Get.find<CartController>().isActive, isFalse);
    await _drain(tester);
  });

  testWidgets('Reprint lists sales newest first and opens a receipt', (
    tester,
  ) async {
    await _boot(tester);
    Get.find<OverlayController>().open('reprint');
    await tester.pumpAndSettle();
    expect(find.text('Recent sales'), findsOneWidget);
    expect(find.text('Select a bill to preview or reprint.'), findsOneWidget);
    expect(find.text('No completed sales yet.'), findsOneWidget);
    Get.find<OverlayController>().close();
    await tester.pumpAndSettle();

    await _payCash(tester);
    await tester.tap(_in(ReceiptDialog, 'New Sale'));
    await tester.pumpAndSettle();
    await _add(tester, 1);
    final pay = Get.find<PaymentController>();
    pay.payment(PaymentMode.cash);
    await tester.pump();
    pay.tendered.text = '100';
    pay.completeCash();
    await tester.pumpAndSettle();
    Get.find<OverlayController>().close();
    await tester.pumpAndSettle();

    Get.find<OverlayController>().open('reprint');
    await tester.pumpAndSettle();
    expect(find.textContaining(' · Walk-in Customer'), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('AX000002 · Walk-in Customer')).dy,
      lessThan(tester.getTopLeft(find.text('AX000001 · Walk-in Customer')).dy),
    );
    await tester.tap(find.text('AX000001 · Walk-in Customer'));
    await tester.pumpAndSettle();
    expect(Get.find<OverlayController>().modal.value, 'receipt');
    expect(_in(ReceiptDialog, 'Bill: AX000001'), findsOneWidget);
    await _drain(tester);
  });

  testWidgets('Print draft shows an unpaid DRAFT receipt', (tester) async {
    await _boot(tester);
    await _add(tester, 5);
    Get.find<OrderMenuController>().printDraft();
    await tester.pumpAndSettle();
    expect(_in(ReceiptDialog, 'Bill: DRAFT'), findsOneWidget);
    expect(_in(ReceiptDialog, 'Unpaid'), findsOneWidget);
    expect(
      _in(ReceiptDialog, '₹0.00'),
      findsNWidgets(3),
    ); // disc, points, change
    expect(Get.find<CartController>().isActive, isTrue, reason: 'untouched');
    await _drain(tester);
  });

  testWidgets('Rename counter: trimmed, blank disabled, shown in the heading', (
    tester,
  ) async {
    await _boot(tester);
    final text = Get.find<TextDialogController>();
    Get.find<OrderMenuController>().renameCounter();
    await tester.pumpAndSettle();
    expect(find.text('Rename counter'), findsWidgets);
    expect(text.text.text, 'C3');
    expect(text.focus.hasFocus, isTrue);

    await tester.enterText(_field(text.text), '   ');
    await tester.pump();
    expect(text.canSave.value, isFalse);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(Get.find<OverlayController>().isOpen, isTrue, reason: 'disabled');

    await tester.enterText(_field(text.text), '  Till 7 ');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(Get.find<SettingsController>().settings.value.counter, 'Till 7');
    expect(Get.find<OverlayController>().isOpen, isFalse);
    await _drain(tester);
  });

  testWidgets('Add note: preloaded, saved as typed, empty clears', (
    tester,
  ) async {
    await _boot(tester);
    await _add(tester, 5);
    final text = Get.find<TextDialogController>();
    final cart = Get.find<CartController>();
    Get.find<OrderMenuController>().addNote();
    await tester.pumpAndSettle();
    expect(find.text('Add order note'), findsOneWidget);
    expect(text.text.text, '');
    await tester.enterText(_field(text.text), ' Gift wrap ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(cart.cart.value.note, ' Gift wrap ');
    expect(find.textContaining('Note:'), findsOneWidget);

    Get.find<OrderMenuController>().addNote();
    await tester.pumpAndSettle();
    expect(text.text.text, ' Gift wrap ');
    await tester.enterText(_field(text.text), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(cart.cart.value.note, '');
    await _drain(tester);
  });

  for (final (platform, label) in <(TargetPlatform, String)>[
    (TargetPlatform.macOS, '⌘K'),
    (TargetPlatform.windows, 'Ctrl+K'),
  ]) {
    testWidgets('shortcuts dialog on $platform', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      try {
        await _boot(tester);
        Get.find<OverlayController>().open('shortcuts');
        await tester.pumpAndSettle();
        expect(find.text('Keyboard shortcuts'), findsOneWidget);
        for (final text in <String>[
          'Focus barcode search',
          'Add scanned product',
          'Cash payment',
          'Card payment',
          'Hold bill',
          'Recall bill',
          'Apply discount',
          'Remove selected line',
          'Close dialog',
        ]) {
          expect(find.text(text), findsOneWidget, reason: text);
        }
        expect(find.text(label), findsWidgets);
        for (final key in <String>[
          'F2',
          'F3',
          'F4',
          'F5',
          'F6',
          'Delete',
          'Esc',
          'Enter',
        ]) {
          expect(find.text(key), findsOneWidget, reason: key);
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(Get.find<OverlayController>().isOpen, isFalse);
        await tester.pump(const Duration(milliseconds: 100));
        expect(Get.find<SearchFieldController>().focusNode.hasFocus, isTrue);
        await _drain(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  test('ReceiptController without a payload has no receipt', () async {
    await bootTestApp();
    expect(Get.find<ReceiptController>().receipt, isNull);
  });
}
