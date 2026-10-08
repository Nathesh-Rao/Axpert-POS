// The S4.c surfaces across window sizes (width 900 to 1900, height 600 to
// 1000): the top-bar results popover, the scan, price check, customer picker
// and add customer dialogs. Texts stay inside the window, blocks stack without
// overlap, paddings and gaps keep their tokens, list rows fit, and the focus
// ring clears the text. Runs on VM and Chrome (widget tests use the wide test
// font, so "one line" is checked in goldens and screenshots, KG-127).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';
import 'package:pos_application/core/responsive/summary_metrics.dart';
import 'package:pos_application/core/theme/tokens/app_checkout_sizes.dart';
import 'package:pos_application/core/theme/tokens/app_sizes.dart';
import 'package:pos_application/modules/customers/controllers/add_customer_controller.dart';
import 'package:pos_application/modules/customers/controllers/customer_picker_controller.dart';
import 'package:pos_application/modules/customers/controllers/customers_controller.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/customers/widgets/add_customer_dialog.dart';
import 'package:pos_application/modules/customers/widgets/customer_picker_dialog.dart';
import 'package:pos_application/modules/pos/controllers/global_search_controller.dart';
import 'package:pos_application/modules/pos/controllers/price_check_controller.dart';
import 'package:pos_application/modules/pos/controllers/scan_controller.dart';
import 'package:pos_application/modules/pos/widgets/dialogs/price_check_dialog.dart';
import 'package:pos_application/modules/pos/widgets/dialogs/scan_dialog.dart';
import 'package:pos_application/modules/shell/widgets/search_results.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';
import 'package:pos_application/shared/widgets/focus_outline.dart';

import '../../support/layout_matrix.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

Finder _field(TextEditingController controller) =>
    find.byWidgetPredicate((w) => w is TextField && w.controller == controller);

Finder _box(TextEditingController controller) =>
    find.ancestor(of: _field(controller), matching: find.byType(FocusOutline));

Future<void> _open(WidgetTester tester, String id) async {
  Get.find<OverlayController>().open(id);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'open $id');
}

Future<void> _close(WidgetTester tester) async {
  Get.find<OverlayController>().close();
  await tester.pumpAndSettle();
}

/// The modal card of [dialog].
Rect _card(WidgetTester tester, Finder dialog) => tester.getRect(
  find.descendant(of: dialog, matching: find.byType(DecoratedBox)).first,
);

void _expectInside(Rect r, Rect outer, double pad, String why) {
  expect(
    r.left - outer.left,
    greaterThanOrEqualTo(pad - 0.5),
    reason: 'left $why',
  );
  expect(
    outer.right - r.right,
    greaterThanOrEqualTo(pad - 0.5),
    reason: 'right $why',
  );
}

/// Consecutive blocks do not overlap (a scrolling dialog may leave the window).
void _expectStacked(List<Rect> blocks, {required String reason}) {
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
      testWidgets('search and pickers at ${w.toInt()} x ${h.toInt()}', (
        tester,
      ) async {
        useLogicalViewport(tester, size);
        final binding = await bootInWidgetTest(tester);
        await tester.pumpWidget(testApp(binding));
        await tester.pumpAndSettle();
        final pad = AppMetrics(size).modalPad;
        final customers = Get.find<CustomersController>();
        customers.customers.addAll(<Customer>[
          for (var i = 0; i < 14; i++)
            Customer(
              id: 'x$i',
              name: 'Customer Number $i',
              phone: '98450${10000 + i}',
              email: '',
              member: 'MG${2000 + i}',
              points: i * 10,
            ),
        ]);
        await tester.pump();

        // ---- top-bar results popover ----
        final search = Get.find<SearchFieldController>();
        search.text.text = 'a';
        Get.find<GlobalSearchController>().refreshNow();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'dropdown');
        final results = Get.find<GlobalSearchController>().matches;
        expect(results.length, 6);
        final field = tester.getRect(find.byType(SearchResultsPortal));
        final popup = find.byKey(const ValueKey<String>('search-results'));
        expect(popup, findsOneWidget);
        Finder inPopup(String text) =>
            find.descendant(of: popup, matching: find.text(text));
        final nameRects = <Rect>[
          for (final p in results) tester.getRect(inPopup(p.name)),
        ];
        _expectStacked(nameRects, reason: 'results at $size');
        expect(
          nameRects.first.left,
          greaterThanOrEqualTo(
            field.left + AppCheckoutSizes.searchResultsPad - 0.5,
          ),
        );
        expect(
          nameRects.last.bottom,
          lessThanOrEqualTo(h + 0.5),
          reason: 'popover inside window',
        );
        expect(
          nameRects.first.top,
          greaterThan(field.bottom),
          reason: 'below the field',
        );
        expect(
          tester.getRect(popup).right,
          lessThanOrEqualTo(field.right + 0.5),
          reason: 'not wider than the field',
        );
        search.text.clear();
        await tester.pumpAndSettle();

        // ---- scan simulator ----
        await _open(tester, 'scan');
        var dialog = find.byType(ScanDialog);
        var card = _card(tester, dialog);
        expect(card.top, greaterThanOrEqualTo(-0.5));
        expect(card.bottom, lessThanOrEqualTo(h + 0.5), reason: 'scan fits');
        final scan = Get.find<ScanController>();
        Rect t(String text) => tester.getRect(
          find.descendant(of: dialog, matching: find.text(text)),
        );
        final scanInput = tester.getRect(_box(scan.text));
        expect(scanInput.height, closeTo(AppSizes.modalInputHeight, 0.01));
        _expectInside(scanInput, card, pad, 'scan input');
        _expectStacked(<Rect>[
          t('Scan simulator'),
          t('Enter a product barcode to simulate your scanner.'),
          scanInput,
          t('Simulate scan'),
        ], reason: 'scan at $size');
        for (final text in <String>[
          'Scan simulator',
          'Scan random product',
          'Simulate scan',
        ]) {
          expectReadable(
            tester,
            find.descendant(of: dialog, matching: find.text(text)),
            size,
            oneLine: false,
            reason: text,
          );
        }
        expectReadable(
          tester,
          find.descendant(
            of: dialog,
            matching: find.textContaining('Try 8901234567890'),
          ),
          size,
          minPerChar: 2,
          oneLine: false,
          reason: 'hint',
        );
        scan.text.text = '8901234567890';
        scan.focus.requestFocus();
        await tester.pump();
        expectRingClearance(
          tester,
          _box(scan.text),
          SummaryMetrics.minRingClearance,
          reason: 'scan input at $size',
        );
        await _close(tester);

        // ---- price check with a result ----
        await _open(tester, 'priceCheck');
        dialog = find.byType(PriceCheckDialog);
        final check = Get.find<PriceCheckController>();
        await tester.enterText(_field(check.text), 'bdv001');
        await tester.pumpAndSettle();
        card = _card(tester, dialog);
        expect(
          card.bottom,
          lessThanOrEqualTo(h + 0.5),
          reason: 'price check fits',
        );
        final checkInput = tester.getRect(_box(check.text));
        expect(checkInput.height, closeTo(AppSizes.modalInputHeight, 0.01));
        _expectInside(checkInput, card, pad, 'price input');
        Rect pt(String text) => tester.getRect(
          find.descendant(of: dialog, matching: find.text(text)),
        );
        final name = pt('Coca Cola 500ml');
        final price = pt('₹40.00');
        final details = pt('BDV001 · 45 in stock · GST 18%');
        _expectStacked(<Rect>[
          checkInput,
          name,
          price,
          details,
        ], reason: 'price at $size');
        // The result box: the content keeps its 25 px padding.
        final resultBox = tester.getRect(
          find
              .ancestor(
                of: find.descendant(
                  of: dialog,
                  matching: find.text('Coca Cola 500ml'),
                ),
                matching: find.byType(Container),
              )
              .first,
        );
        for (final r in <Rect>[name, price, details]) {
          expect(
            r.left - resultBox.left,
            greaterThanOrEqualTo(AppCheckoutSizes.priceResultPad - 0.5),
          );
          expect(
            resultBox.right - r.right,
            greaterThanOrEqualTo(AppCheckoutSizes.priceResultPad - 0.5),
          );
        }
        expect(
          resultBox.top - checkInput.bottom,
          greaterThanOrEqualTo(AppCheckoutSizes.priceResultMarginTop - 0.5),
        );
        expectReadable(
          tester,
          find.descendant(of: dialog, matching: find.text('₹40.00')),
          size,
          minPerChar: 5,
          reason: 'price',
        );
        check.focus.requestFocus();
        await tester.pump();
        expectRingClearance(
          tester,
          _box(check.text),
          SummaryMetrics.minRingClearance,
          reason: 'price input at $size',
        );
        await _close(tester);

        // ---- customer picker (18 rows, the list scrolls) ----
        await _open(tester, 'customers');
        dialog = find.byType(CustomerPickerDialog);
        card = _card(tester, dialog);
        expect(card.bottom, lessThanOrEqualTo(h + 0.5), reason: 'picker fits');
        final picker = Get.find<CustomerPickerController>();
        final pickerInput = tester.getRect(_box(picker.search));
        expect(pickerInput.height, closeTo(AppSizes.modalInputHeight, 0.01));
        _expectInside(pickerInput, card, pad, 'picker input');
        final listFinder = find.descendant(
          of: dialog,
          matching: find.byType(ListView),
        );
        final list = tester.getRect(listFinder);
        final cap = [
          AppCheckoutSizes.modalListMaxHeight,
          h * AppCheckoutSizes.modalListMaxHeightFraction,
        ].reduce((a, b) => a < b ? a : b);
        expect(
          list.height,
          lessThanOrEqualTo(cap + 0.5),
          reason: 'list $list cap $cap',
        );
        expect(
          list.top,
          greaterThanOrEqualTo(pickerInput.bottom),
          reason: 'list below input',
        );
        final scroll = tester.state<ScrollableState>(
          find
              .descendant(of: listFinder, matching: find.byType(Scrollable))
              .first,
        );
        expect(
          scroll.position.maxScrollExtent,
          greaterThan(0),
          reason: '18 rows scroll',
        );
        // The first row: content inset by the row padding, inside the list.
        final rowTitle = tester.getRect(
          find.descendant(of: dialog, matching: find.text('Walk-in Customer')),
        );
        expect(
          rowTitle.left - list.left,
          greaterThanOrEqualTo(
            AppCheckoutSizes.modalListRowPadX +
                AppCheckoutSizes.pickerUserIcon -
                0.5,
          ),
        );
        expect(
          rowTitle.top - list.top,
          greaterThanOrEqualTo(AppCheckoutSizes.modalListRowPadY - 0.5),
        );
        expectReadable(
          tester,
          find.descendant(of: dialog, matching: find.text('Find a customer')),
          size,
          oneLine: false,
          reason: 'picker title',
        );
        final addButton = tester.getRect(
          find.descendant(of: dialog, matching: find.text('Add Customer')),
        );
        expect(
          addButton.top,
          greaterThanOrEqualTo(list.bottom - 0.5),
          reason: 'button below the list',
        );
        expect(
          addButton.bottom,
          lessThanOrEqualTo(card.bottom - pad + 0.5),
          reason: 'button inside the padding',
        );
        picker.search.text = 'customer';
        picker.searchFocus.requestFocus();
        await tester.pump();
        expectRingClearance(
          tester,
          _box(picker.search),
          SummaryMetrics.minRingClearance,
          reason: 'picker search at $size',
        );
        picker.search.clear();
        await tester.pump(const Duration(milliseconds: 250));
        await _close(tester);

        // ---- add customer ----
        await _open(tester, 'addCustomer');
        dialog = find.byType(AddCustomerDialog);
        card = _card(tester, dialog);
        final add = Get.find<AddCustomerController>();
        final boxes = <Rect>[
          tester.getRect(_box(add.name)),
          tester.getRect(_box(add.phone)),
          tester.getRect(_box(add.email)),
        ];
        final labels = <Rect>[
          for (final l in <String>['Name *', 'Phone *', 'Email'])
            tester.getRect(find.descendant(of: dialog, matching: find.text(l))),
        ];
        final saveText = tester.getRect(
          find.descendant(of: dialog, matching: find.text('Save customer')),
        );
        final stack = <Rect>[
          labels[0],
          boxes[0],
          labels[1],
          boxes[1],
          labels[2],
          boxes[2],
          saveText,
        ];
        _expectStacked(stack, reason: 'add customer at $size');
        for (var i = 0; i < 3; i++) {
          expect(boxes[i].height, closeTo(AppSizes.modalInputHeight, 0.01));
          _expectInside(boxes[i], card, pad, 'add field $i');
          expectGap(
            labels[i],
            boxes[i],
            SummaryMetrics.minLabelGap,
            reason: 'label $i',
          );
        }
        expectGap(
          boxes[0],
          labels[1],
          SummaryMetrics.minRowGap,
          reason: 'rows 0-1',
        );
        expectGap(
          boxes[1],
          labels[2],
          SummaryMetrics.minRowGap,
          reason: 'rows 1-2',
        );
        // The save button spans the modal content (full width).
        final saveBox = tester.getRect(
          find
              .ancestor(
                of: find.descendant(
                  of: dialog,
                  matching: find.text('Save customer'),
                ),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          saveBox.width,
          closeTo(card.width - 2 * pad, 1.0),
          reason: 'full width',
        );
        expect(
          card.bottom,
          lessThanOrEqualTo(h + 0.5),
          reason: 'add customer fits $card',
        );
        expect(
          card.top,
          greaterThanOrEqualTo(-0.5),
          reason: 'add customer top $card',
        );
        add.name.text = 'Ravi';
        await tester.pump();
        await tester.tap(_field(add.name), warnIfMissed: false);
        await tester.pump();
        expectRingClearance(
          tester,
          _box(add.name),
          SummaryMetrics.minRingClearance,
          reason: 'add name at $size',
        );
        await _close(tester);
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
      });
    }
  }
}
