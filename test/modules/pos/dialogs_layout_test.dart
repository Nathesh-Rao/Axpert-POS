// The recall dialog and the discount drawer across window sizes (width 900 to
// 1900, height 600 to 1000): no clipped or wrapped text, nothing outside the
// window, no overlapping blocks, the inner padding and gap tokens, and the
// focus ring clearance of the drawer inputs. Runs on VM and Chrome.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';
import 'package:pos_application/core/responsive/summary_metrics.dart';
import 'package:pos_application/core/theme/tokens/app_checkout_sizes.dart';
import 'package:pos_application/core/theme/tokens/app_sizes.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/discount_form_controller.dart';
import 'package:pos_application/modules/pos/controllers/hold_recall_controller.dart';
import 'package:pos_application/modules/pos/widgets/dialogs/discount_drawer.dart';
import 'package:pos_application/modules/pos/widgets/dialogs/recall_dialog.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/widgets/focus_outline.dart';

import '../../support/layout_matrix.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

Future<void> _bootWithBills(WidgetTester tester, Size size, int bills) async {
  useLogicalViewport(tester, size);
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  final flow = Get.find<HoldRecallController>();
  final products = Get.find<ProductsController>();
  for (var i = 0; i < bills; i++) {
    Get.find<CartActionsController>().add(products.byId(1 + i % 6)!);
    flow.hold();
  }
  await tester.pump();
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

/// Consecutive blocks do not overlap and none leaves the window.
void _expectStacked(List<Rect> blocks, Size window, {required String reason}) {
  for (var i = 0; i < blocks.length; i++) {
    expect(blocks[i].top, greaterThanOrEqualTo(-0.5), reason: 'top $i $reason');
    expect(
      blocks[i].bottom,
      lessThanOrEqualTo(window.height + 0.5),
      reason: 'bottom $i ${blocks[i]} $reason',
    );
    if (i > 0) {
      expect(
        blocks[i].top,
        greaterThanOrEqualTo(blocks[i - 1].bottom - 0.01),
        reason: 'overlap ${blocks[i - 1]} / ${blocks[i]} $reason',
      );
    }
  }
}

void main() {
  useTestApp();

  for (final w in matrixWidths) {
    for (final h in matrixHeights) {
      final size = Size(w, h);
      testWidgets('recall dialog at ${w.toInt()} x ${h.toInt()}', (
        tester,
      ) async {
        await _bootWithBills(tester, size, 9);
        Get.find<HoldRecallController>().openRecall();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final dialog = find.byType(RecallDialog);
        final modal = tester.getRect(
          find
              .descendant(of: dialog, matching: find.byType(DecoratedBox))
              .first,
        );
        expect(modal.left, greaterThanOrEqualTo(0), reason: 'modal left');
        expect(modal.right, lessThanOrEqualTo(w), reason: 'modal right');
        expect(
          modal.top,
          greaterThanOrEqualTo(-0.5),
          reason: 'modal top $modal',
        );
        expect(
          modal.bottom,
          lessThanOrEqualTo(h + 0.5),
          reason: 'modal bottom $modal',
        );
        final pad = AppMetrics(size).modalPad;

        expectReadable(
          tester,
          find.text('Held bills'),
          size,
          oneLine: false,
          reason: 'title',
        );
        expectReadable(
          tester,
          find.text('Pick up right where you left off.'),
          size,
          minPerChar: 2,
          oneLine: false,
          reason: 'subtitle',
        );
        // The list is at most min(400, 40% of the height) high and scrolls.
        final list = tester.getRect(
          find.descendant(
            of: dialog,
            matching: find.byType(SingleChildScrollView),
          ),
        );
        final cap = [
          AppCheckoutSizes.modalListMaxHeight,
          h * AppCheckoutSizes.modalListMaxHeightFraction,
        ].reduce((a, b) => a < b ? a : b);
        expect(
          list.height,
          lessThanOrEqualTo(cap + 0.5),
          reason: 'list $list cap $cap',
        );
        expect(list.height, greaterThan(0));
        expect(list.left - modal.left, greaterThanOrEqualTo(pad - 0.5));
        expect(modal.right - list.right, greaterThanOrEqualTo(pad - 0.5));

        // Each visible row: one line of title, inside the row padding.
        final titles = find.textContaining(' items');
        expect(titles, findsWidgets);
        final first = titles.first;
        expectReadable(
          tester,
          first,
          size,
          minPerChar: 3,
          oneLine: false,
          reason: 'row title',
        );
        final rowRect = tester.getRect(
          find.ancestor(of: first, matching: find.byType(Container)).first,
        );
        final titleRect = tester.getRect(first);
        expect(
          titleRect.left - rowRect.left,
          greaterThanOrEqualTo(AppCheckoutSizes.modalListRowPadX - 0.01),
          reason: 'row padding left',
        );
        expect(
          titleRect.top - rowRect.top,
          greaterThanOrEqualTo(AppCheckoutSizes.modalListRowPadY - 0.01),
          reason: 'row padding top',
        );
        expectReadable(
          tester,
          find.text('₹21.00').first,
          size,
          minPerChar: 5,
          oneLine: false,
          reason: 'row total',
        );

        // Scrolling the list to the end works and keeps the dialog in place.
        await tester.drag(
          find.descendant(
            of: dialog,
            matching: find.byType(SingleChildScrollView),
          ),
          const Offset(0, -2000),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        // The question after picking a bill with an active cart.
        Get.find<CartActionsController>().add(
          Get.find<ProductsController>().byId(5)!,
        );
        await tester.pump();
        final flow = Get.find<HoldRecallController>();
        flow.pending.value = flow.held.bills.first;
        await tester.pumpAndSettle();
        expect(find.text('You have an active cart'), findsOneWidget);
        final conflict = <Rect>[
          tester.getRect(find.text('You have an active cart')),
          tester.getRect(find.textContaining('Hold your current cart')),
          tester.getRect(find.text('Replace current')),
        ];
        _expectStacked(conflict, size, reason: 'conflict at $size');
        expectReadable(
          tester,
          find.text('You have an active cart'),
          size,
          oneLine: false,
          reason: 'conflict title',
        );
        expectReadable(
          tester,
          find.text('Replace current'),
          size,
          oneLine: false,
          reason: 'replace',
        );
        expectReadable(
          tester,
          find.text('Hold & recall'),
          size,
          oneLine: false,
          reason: 'hold and recall',
        );
        final actions = tester.getRect(find.text('Hold & recall'));
        expect(
          actions.right,
          lessThanOrEqualTo(modal.right - pad + 0.5),
          reason: 'actions inset',
        );
        await _drain(tester);
      });

      testWidgets('discount drawer at ${w.toInt()} x ${h.toInt()}', (
        tester,
      ) async {
        await _bootWithBills(tester, size, 0);
        Get.find<CartActionsController>().add(
          Get.find<ProductsController>().byId(5)!,
        );
        await tester.pump();
        Get.find<DiscountFormController>().open();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(Get.find<OverlayController>().modal.value, 'discount');

        final drawer = find.byType(DiscountDrawer);
        final box = tester.getRect(
          find
              .descendant(of: drawer, matching: find.byType(DecoratedBox))
              .first,
        );
        final width = w < AppSizes.drawerWidth ? w : AppSizes.drawerWidth;
        expect(box.right, closeTo(w, 0.5), reason: 'docked right');
        expect(box.width, closeTo(width, 0.5), reason: 'width');
        expect(box.top, closeTo(0, 0.5), reason: 'full height top');
        expect(box.bottom, closeTo(h, 0.5), reason: 'full height bottom');
        final pad = AppMetrics(size).modalPad;

        Finder inDrawer(String text) =>
            find.descendant(of: drawer, matching: find.text(text));
        for (final text in <String>[
          'Bill discount',
          'Percentage %',
          'Flat amount ₹',
          'Discount',
          'Reason',
          'Remove',
          'Apply discount',
        ]) {
          expectReadable(
            tester,
            inDrawer(text),
            size,
            oneLine: false,
            reason: text,
          );
        }
        expectReadable(
          tester,
          inDrawer('Apply a discount to this entire bill.'),
          size,
          minPerChar: 2,
          oneLine: false,
          reason: 'subtitle',
        );

        // Left and right padding of the content.
        final form = Get.find<DiscountFormController>();
        for (final controller in <TextEditingController>[
          form.value,
          form.reason,
        ]) {
          final field = tester.getRect(
            find.ancestor(
              of: find.byWidgetPredicate(
                (x) => x is TextField && x.controller == controller,
              ),
              matching: find.byType(FocusOutline),
            ),
          );
          expect(
            field.left - box.left,
            greaterThanOrEqualTo(pad - 0.5),
            reason: 'field left',
          );
          expect(
            box.right - field.right,
            greaterThanOrEqualTo(pad - 0.5),
            reason: 'field right',
          );
          expect(field.height, AppSizes.modalInputHeight);
        }

        // Vertical stack: nothing overlaps, label to input at least 4 px.
        final valueBox = tester.getRect(
          find.ancestor(
            of: find.byWidgetPredicate(
              (x) => x is TextField && x.controller == form.value,
            ),
            matching: find.byType(FocusOutline),
          ),
        );
        final reasonBox = tester.getRect(
          find.ancestor(
            of: find.byWidgetPredicate(
              (x) => x is TextField && x.controller == form.reason,
            ),
            matching: find.byType(FocusOutline),
          ),
        );
        final stack = <Rect>[
          tester.getRect(inDrawer('Bill discount')),
          tester.getRect(inDrawer('Apply a discount to this entire bill.')),
          tester.getRect(inDrawer('Percentage %')),
          tester.getRect(inDrawer('Discount')),
          valueBox,
          tester.getRect(inDrawer('Reason')),
          reasonBox,
          tester.getRect(inDrawer('Apply discount')),
        ];
        final scroll = tester.state<ScrollableState>(
          find.descendant(of: drawer, matching: find.byType(Scrollable)).first,
        );
        final scrolls = scroll.position.maxScrollExtent > 0.5;
        if (!scrolls) _expectStacked(stack, size, reason: 'drawer at $size');
        for (var i = 1; i < stack.length; i++) {
          expect(
            stack[i].top,
            greaterThanOrEqualTo(stack[i - 1].bottom - 0.01),
            reason: 'overlap ${stack[i - 1]} / ${stack[i]}',
          );
        }
        expectGap(
          stack[3],
          valueBox,
          SummaryMetrics.minLabelGap,
          reason: 'discount label',
        );
        expectGap(
          stack[5],
          reasonBox,
          SummaryMetrics.minLabelGap,
          reason: 'reason label',
        );
        expectGap(valueBox, stack[5], SummaryMetrics.minRowGap, reason: 'rows');
        // The buttons are reachable: inside the window or by scrolling.
        if (!scrolls) {
          expect(
            stack.last.bottom,
            lessThanOrEqualTo(h + 0.5),
            reason: 'apply visible',
          );
        } else {
          await tester.ensureVisible(inDrawer('Apply discount'));
          await tester.pump();
          expect(
            tester.getRect(inDrawer('Apply discount')).bottom,
            lessThanOrEqualTo(h + 0.5),
            reason: 'apply reachable by scrolling',
          );
          await tester.ensureVisible(inDrawer('Bill discount'));
          await tester.pump();
        }

        // Focus ring clearance of the number field.
        form.value.text = '12.5';
        form.valueFocus.requestFocus();
        await tester.pump();
        expectRingClearance(
          tester,
          find.ancestor(
            of: find.byWidgetPredicate(
              (x) => x is TextField && x.controller == form.value,
            ),
            matching: find.byType(FocusOutline),
          ),
          SummaryMetrics.minRingClearance,
          reason: 'discount value at $size',
        );
        await _drain(tester);
      });
    }
  }
}
