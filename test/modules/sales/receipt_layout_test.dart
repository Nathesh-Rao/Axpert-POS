// The S4.d surfaces across window sizes (width 900 to 1900, height 600 to
// 1000): the receipt (1 line, 30 lines with a very long name and large
// amounts, a 3-decimal currency), Reprint, Rename counter, Add note and the
// shortcuts dialog. Asserts: nothing outside the window, nothing overlapping,
// paddings and gaps, receipt cells inside their columns, list and card
// heights. Runs on VM and Chrome (the wide test font means "one line" is
// judged in goldens and screenshots, KG-127).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';
import 'package:pos_application/core/responsive/summary_metrics.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/theme/tokens/app_checkout_sizes.dart';
import 'package:pos_application/core/theme/tokens/app_sizes.dart';
import 'package:pos_application/modules/pos/controllers/order_menu_controller.dart';
import 'package:pos_application/modules/pos/controllers/text_dialog_controller.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/products/models/product.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';
import 'package:pos_application/modules/sales/models/sale.dart';
import 'package:pos_application/modules/sales/widgets/receipt_dialog.dart';
import 'package:pos_application/modules/sales/widgets/reprint_dialog.dart';
import 'package:pos_application/modules/shell/widgets/shortcuts_dialog.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/widgets/focus_outline.dart';

import '../../support/layout_matrix.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

const String _longName =
    'Extra Large Family Pack Roasted Salted Cashew Nuts With Himalayan '
    'Pink Salt and Black Pepper 1kg Resealable Pouch';

Product _product(int id, String name, Currency currency, int priceMinor) =>
    Product(
      id: id,
      name: name,
      code: 'C$id',
      barcode: 'B$id',
      price: Money(priceMinor, currency),
      category: 'c',
      sub: 's',
      stock: 100,
      gst: const Bp(500),
      image: -1,
      favourite: false,
    );

Sale _sale({
  required String number,
  required int lines,
  Currency currency = CurrencyRegistry.inr,
  int priceMinor = 2000,
  bool longName = false,
  String customer = 'Walk-in Customer',
}) {
  final cartLines = <CartLine>[
    for (var i = 0; i < lines; i++)
      CartLine(
        product: _product(
          i + 1,
          longName ? '$_longName $i' : 'Lays Classic 52g',
          currency,
          priceMinor,
        ),
        qty: Qty(1000 + i * 250),
        price: Money(priceMinor, currency),
        discount: Bp.zero,
      ),
  ];
  Money m(int v) => Money(v, currency);
  return Sale(
    number: number,
    date: '2026-10-08T11:16:04.000Z',
    store: 'Maison Galaxy - Ozone',
    customer: customer,
    cart: Cart(lines: cartLines),
    totals: SaleTotals(
      items: lines,
      qty: Qty(1000 * lines),
      value: m(priceMinor * lines),
      subtotal: m(priceMinor * lines),
      discount: m(priceMinor ~/ 10),
      tax: m(priceMinor ~/ 5),
      points: m(0),
      total: m(priceMinor * lines),
    ),
    mode: 'Cash',
    tendered: m(priceMinor * lines),
    change: m(0),
    returned: const <int, Qty>{},
  );
}

Rect _r(WidgetTester t, Finder f) => t.getRect(f);

void _expectNoOverlap(List<Rect> blocks, String reason) {
  for (var i = 1; i < blocks.length; i++) {
    expect(
      blocks[i].top,
      greaterThanOrEqualTo(blocks[i - 1].bottom - 0.01),
      reason: 'overlap ${blocks[i - 1]} / ${blocks[i]} $reason',
    );
  }
}

void main() {
  useTestApp();

  for (final w in matrixWidths) {
    for (final h in matrixHeights) {
      final size = Size(w, h);
      testWidgets('receipt and help at ${w.toInt()} x ${h.toInt()}', (
        tester,
      ) async {
        useLogicalViewport(tester, size);
        final binding = await bootInWidgetTest(tester);
        await tester.pumpWidget(testApp(binding));
        await tester.pumpAndSettle();
        final overlay = Get.find<OverlayController>();
        final pad = AppMetrics(size).modalPad;

        Future<void> checkReceipt(Sale sale, String label) async {
          overlay.open('receipt', payload: sale);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: label);
          final dialog = find.byType(ReceiptDialog);
          Finder t(String text) =>
              find.descendant(of: dialog, matching: find.text(text));
          final card = _r(
            tester,
            find
                .descendant(of: dialog, matching: find.byType(DecoratedBox))
                .first,
          );
          final why = '$label at $size card $card';
          expect(card.left, greaterThanOrEqualTo(-0.5), reason: why);
          expect(card.right, lessThanOrEqualTo(w + 0.5), reason: why);
          expect(card.top, greaterThanOrEqualTo(-0.5), reason: why);
          expect(card.bottom, lessThanOrEqualTo(h + 0.5), reason: why);
          expect(card.height, lessThanOrEqualTo(h - 32 + 0.5), reason: why);
          expect(
            card.width,
            lessThanOrEqualTo(AppSizes.receiptModalWidth + 0.5),
          );

          // The scrolling card keeps the blocks in order, never overlapping.
          final scroll = tester.state<ScrollableState>(
            find
                .descendant(of: dialog, matching: find.byType(Scrollable))
                .first,
          );
          if (scroll.position.maxScrollExtent > 0) {
            scroll.position.jumpTo(0);
            await tester.pump();
          }
          final blocks = <Rect>[
            _r(tester, t('AXPERT POS')),
            _r(tester, t('Maison Galaxy - Ozone')),
            _r(tester, t('Retail tax invoice')),
            _r(tester, t('Bill: ${sale.number}')),
            _r(tester, t('Cashier: MGTCASH3')),
            _r(tester, t('Customer: ${sale.customer}')),
          ];
          _expectNoOverlap(blocks, why);
          // Left padding of the receipt content (centred and left texts).
          for (final b in blocks) {
            expect(
              b.left - card.left,
              greaterThanOrEqualTo(pad - 0.5),
              reason: why,
            );
            expect(
              card.right - b.right,
              greaterThanOrEqualTo(pad - 0.5),
              reason: why,
            );
          }

          // The items list: 100 px minimum, 26 % of the height at most.
          final list = _r(
            tester,
            find
                .descendant(
                  of: dialog,
                  matching: find.byType(SingleChildScrollView),
                )
                .at(1),
          );
          final cap = h * AppCheckoutSizes.receiptItemsMaxFraction;
          final maxList = cap < 100 ? 100.0 : cap;
          expect(list.height, lessThanOrEqualTo(maxList + 0.5), reason: why);
          expect(list.height, greaterThanOrEqualTo(100 - 0.5), reason: why);
          expect(list.left - card.left, greaterThanOrEqualTo(pad - 0.5));
          expect(card.right - list.right, greaterThanOrEqualTo(pad - 0.5));

          // The first table row's cells sit in their columns.
          final table = find.descendant(
            of: dialog,
            matching: find.byType(Table),
          );
          final first = sale.cart.lines.first;
          final name = _r(
            tester,
            find
                .descendant(
                  of: table,
                  matching: find.textContaining(first.product.name),
                )
                .first,
          );
          final qty = _r(
            tester,
            find.descendant(of: table, matching: find.text('1.000')).first,
          );
          expect(name.left, greaterThanOrEqualTo(list.left - 0.5), reason: why);
          expect(
            name.right,
            lessThanOrEqualTo(qty.left + 0.5),
            reason: 'name / qty $why',
          );
          final totalText = find
              .descendant(
                of: table,
                matching: find.textContaining(first.price.currency.symbol),
              )
              .first;
          final total = _r(tester, totalText);
          expect(
            qty.right,
            lessThanOrEqualTo(total.left + 0.5),
            reason: 'qty / total $why',
          );
          expect(total.right, lessThanOrEqualTo(list.right + 0.5), reason: why);
          expectReadable(
            tester,
            totalText,
            size,
            minPerChar: 4,
            oneLine: false,
            reason: 'line total',
          );

          // Totals: labels left, amounts right, no overlap, inside the padding.
          for (final label in <String>[
            'Subtotal',
            'Discount',
            'Reward Points',
            'GST',
            'Payment',
            'Change',
          ]) {
            final r = _r(tester, t(label));
            expect(
              r.left - card.left,
              greaterThanOrEqualTo(pad - 0.5),
              reason: '$label $why',
            );
          }
          final labels = <Rect>[
            _r(tester, t('Subtotal')),
            _r(tester, t('Discount')),
            _r(tester, t('Reward Points')),
            _r(tester, t('GST')),
            _r(tester, t('Payment')),
            _r(tester, t('Change')),
            _r(tester, t('Thank you for shopping with us!')),
          ];
          _expectNoOverlap(labels, why);
          final grand = _r(
            tester,
            find.descendant(of: dialog, matching: find.text('Total')).last,
          );
          expect(
            grand.top,
            greaterThanOrEqualTo(labels[3].bottom - 0.01),
            reason: why,
          );
          expect(
            grand.bottom,
            lessThanOrEqualTo(labels[4].top + 0.01),
            reason: why,
          );

          // Print, Email, WhatsApp: equal widths inside the padding, 6 px apart.
          final buttons = <Rect>[
            for (final b in <String>['Print', 'Email', 'WhatsApp'])
              _r(
                tester,
                find.ancestor(of: t(b), matching: find.byType(Container)).first,
              ),
          ];
          expect(buttons[0].width, closeTo(buttons[1].width, 0.5), reason: why);
          expect(buttons[1].width, closeTo(buttons[2].width, 0.5), reason: why);
          expect(
            buttons[1].left - buttons[0].right,
            closeTo(AppCheckoutSizes.receiptActionsGap, 0.5),
            reason: why,
          );
          expect(
            buttons[0].left - card.left,
            greaterThanOrEqualTo(pad - 0.5),
            reason: why,
          );
          expect(
            card.right - buttons[2].right,
            greaterThanOrEqualTo(pad - 0.5),
            reason: why,
          );
          final newSale = _r(
            tester,
            find
                .ancestor(of: t('New Sale'), matching: find.byType(Container))
                .first,
          );
          expect(
            newSale.width,
            closeTo(card.width - 2 * pad, 1.0),
            reason: why,
          );
          expect(
            newSale.top - buttons[0].bottom,
            greaterThanOrEqualTo(AppCheckoutSizes.primaryFullMarginTop - 0.5),
            reason: why,
          );
          // The whole receipt is reachable: the last button by scrolling.
          if (scroll.position.maxScrollExtent > 0) {
            await tester.ensureVisible(t('New Sale'));
            await tester.pump();
            expect(
              _r(tester, t('New Sale')).bottom,
              lessThanOrEqualTo(h + 0.5),
              reason: 'reachable $why',
            );
          }
          overlay.close();
          await tester.pumpAndSettle();
        }

        await checkReceipt(_sale(number: 'AX000001', lines: 1), 'one line');
        await checkReceipt(
          _sale(
            number: 'AX000002',
            lines: 30,
            longName: true,
            priceMinor: 123456789,
            customer: 'Ananya Sharma',
          ),
          '30 long lines, large amounts',
        );
        await checkReceipt(
          _sale(
            number: 'AX000003',
            lines: 3,
            currency: CurrencyRegistry.tnd,
            priceMinor: 12345678,
          ),
          'three decimals',
        );

        // ---- Reprint with 12 sales ----
        final sales = Get.find<SalesController>();
        for (var i = 0; i < 12; i++) {
          sales.sales.add(_sale(number: 'AX${100000 + i}', lines: 2));
        }
        overlay.open('reprint');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'reprint');
        var dialog = find.byType(ReprintDialog);
        var card = _r(
          tester,
          find
              .descendant(of: dialog, matching: find.byType(DecoratedBox))
              .first,
        );
        expect(
          card.bottom,
          lessThanOrEqualTo(h + 0.5),
          reason: 'reprint card $card at $size',
        );
        expect(card.top, greaterThanOrEqualTo(-0.5));
        final listBox = _r(
          tester,
          find.descendant(
            of: dialog,
            matching: find.byType(SingleChildScrollView),
          ),
        );
        final listCap = [
          AppCheckoutSizes.modalListMaxHeight,
          h * AppCheckoutSizes.modalListMaxHeightFraction,
        ].reduce((a, b) => a < b ? a : b);
        expect(
          listBox.height,
          lessThanOrEqualTo(listCap + 0.5),
          reason: 'reprint list at $size',
        );
        final first = _r(
          tester,
          find.descendant(
            of: dialog,
            matching: find.text('AX100011 · Walk-in Customer'),
          ),
        );
        expect(
          first.left - listBox.left,
          greaterThanOrEqualTo(
            AppCheckoutSizes.modalListRowPadX +
                AppCheckoutSizes.pickerUserIcon -
                0.5,
          ),
        );
        expect(
          first.top - listBox.top,
          greaterThanOrEqualTo(AppCheckoutSizes.modalListRowPadY - 0.5),
        );
        overlay.close();
        await tester.pumpAndSettle();

        // ---- Rename counter and Add note ----
        final text = Get.find<TextDialogController>();
        for (final note in <bool>[false, true]) {
          final menu = Get.find<OrderMenuController>();
          note ? menu.addNote() : menu.renameCounter();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final input = _r(
            tester,
            find.ancestor(
              of: find.byWidgetPredicate(
                (x) => x is TextField && x.controller == text.text,
              ),
              matching: find.byType(FocusOutline),
            ),
          );
          final title = note ? 'Add order note' : 'Rename counter';
          final dlg = find
              .ancestor(
                of: find.text(title).first,
                matching: find.byType(DecoratedBox),
              )
              .last;
          final c = _r(tester, dlg);
          expect(input.height, closeTo(AppSizes.modalInputHeight, 0.01));
          expect(input.left - c.left, greaterThanOrEqualTo(pad - 0.5));
          expect(c.right - input.right, greaterThanOrEqualTo(pad - 0.5));
          final save = _r(tester, find.text('Save'));
          final heading = _r(tester, find.text(title).first);
          _expectNoOverlap(<Rect>[
            heading,
            input,
            save,
          ], 'text dialog at $size');
          expect(
            input.top - heading.bottom,
            greaterThanOrEqualTo(SummaryMetrics.minRowGap - 0.01),
          );
          expect(
            save.top - input.bottom,
            greaterThanOrEqualTo(SummaryMetrics.minRowGap - 0.01),
          );
          text.text.text = 'Counter 7';
          text.focus.requestFocus();
          await tester.pump();
          expectRingClearance(
            tester,
            find.ancestor(
              of: find.byWidgetPredicate(
                (x) => x is TextField && x.controller == text.text,
              ),
              matching: find.byType(FocusOutline),
            ),
            SummaryMetrics.minRingClearance,
            reason: '$title at $size',
          );
          overlay.close();
          await tester.pumpAndSettle();
        }

        // ---- Shortcuts help ----
        overlay.open('shortcuts');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'shortcuts');
        dialog = find.byType(ShortcutsDialog);
        card = _r(
          tester,
          find
              .descendant(of: dialog, matching: find.byType(DecoratedBox))
              .first,
        );
        expect(
          card.bottom,
          lessThanOrEqualTo(h + 0.5),
          reason: 'shortcuts card $card at $size',
        );
        final rows = <String>[
          'Focus barcode search',
          'Add scanned product',
          'Cash payment',
          'Card payment',
          'Hold bill',
          'Recall bill',
          'Apply discount',
          'Remove selected line',
          'Close dialog',
        ];
        final scroll = tester.state<ScrollableState>(
          find.descendant(of: dialog, matching: find.byType(Scrollable)).first,
        );
        final rects = <Rect>[
          for (final r in rows)
            _r(tester, find.descendant(of: dialog, matching: find.text(r))),
        ];
        _expectNoOverlap(rects, 'shortcut rows at $size');
        for (var i = 0; i < rows.length; i++) {
          expect(rects[i].left - card.left, greaterThanOrEqualTo(pad - 0.5));
        }
        // Each key chip sits right of its text, inside the padding.
        final fkey = _r(
          tester,
          find.descendant(of: dialog, matching: find.text('F2')),
        );
        final cash = rects[2];
        expect(
          fkey.left,
          greaterThanOrEqualTo(cash.right - 0.5),
          reason: 'kbd beside text',
        );
        expect(
          card.right - fkey.right,
          greaterThanOrEqualTo(pad + AppCheckoutSizes.kbdPadX - 0.5),
        );
        if (scroll.position.maxScrollExtent > 0) {
          await tester.ensureVisible(
            find.descendant(of: dialog, matching: find.text('Close dialog')),
          );
          await tester.pump();
        }
        overlay.close();
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
      });
    }
  }
}
