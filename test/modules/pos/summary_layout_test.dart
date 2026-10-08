// The Bill Summary and the cart panel across window sizes (width 1000 to 1900,
// height 600 to 1000): flutter_test fails on any RenderFlex error, and key
// texts are measured (one line, no per-character wrapping, inside the
// window). Runs on VM and Chrome.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';
import 'package:pos_application/core/responsive/summary_metrics.dart';
import 'package:flutter/rendering.dart';
import 'package:pos_application/core/theme/tokens/app_sizes.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/payment_controller.dart';
import 'package:pos_application/modules/pos/models/payment_state.dart';
import 'package:pos_application/modules/pos/widgets/summary/summary_card.dart';
import 'package:pos_application/shared/widgets/focus_outline.dart';
import 'package:pos_application/modules/pos/widgets/summary/bill_summary_body.dart';
import 'package:pos_application/modules/pos/widgets/summary/cash_panel.dart';
import 'package:pos_application/modules/pos/widgets/summary/forex_card.dart';
import 'package:pos_application/modules/pos/widgets/summary/member_card.dart';
import 'package:pos_application/modules/pos/widgets/summary/payment_section.dart';
import 'package:pos_application/modules/pos/widgets/summary/quick_actions_grid.dart';
import 'package:pos_application/modules/pos/widgets/summary/totals_card.dart';
import 'package:pos_application/shared/widgets/app_input_box.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';

import '../../support/layout_matrix.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

void main() {
  useTestApp();

  for (final w in matrixWidths) {
    for (final h in matrixHeights) {
      testWidgets('summary and cart panel at ${w.toInt()} x ${h.toInt()}', (
        tester,
      ) async {
        final size = Size(w, h);
        useLogicalViewport(tester, size);
        final binding = await bootInWidgetTest(tester);
        await tester.pumpWidget(testApp(binding));
        await tester.pumpAndSettle();

        // Empty cart: the customer chip header.
        for (final text in <String>['Cash Sale', 'Credit Sale']) {
          expectReadable(tester, find.text(text), size, reason: 'empty $text');
        }
        expect(tester.takeException(), isNull);

        Get.find<CartActionsController>().add(
          Get.find<ProductsController>().byId(5)!,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);

        for (final text in <String>[
          'Subtotal',
          'Invoice Total',
          'Amount Due',
          'Change Due',
          'Complete Payment',
          'Cash Sale',
          'Credit Sale',
          'Add Customer',
          'Customer',
          'Exact',
        ]) {
          expectReadable(tester, find.text(text), size, reason: text);
        }
        // Money values keep their full text on one line.
        for (final value in <String>['₹21.00', '₹20.00']) {
          expect(find.text(value), findsWidgets);
          expectReadable(tester, find.text(value).first, size, minPerChar: 5);
        }
        // From height 820 up the whole checkout section is visible: the
        // Complete button lies inside the window.
        if (h >= 820) {
          final rect = tester.getRect(find.text('Complete Payment'));
          expect(rect.bottom, lessThanOrEqualTo(h), reason: 'complete visible');
        }
        _expectSpacing(tester, size);
        _expectNoClippedInputs(tester, size);
        _expectInnerPadding(tester, size);
        _expectInnerGaps(tester, size);
        await _expectRingClearance(tester, size);
        // Card mode: the terminal and decline option keep the same insets.
        Get.find<PaymentController>().payment(PaymentMode.card);
        await tester.pump(const Duration(milliseconds: 100));
        _expectInnerPadding(tester, size, mode: 'card mode');
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
      });
    }
  }
}

/// Cards stack top to bottom with gaps between [minCardGap] and [maxCardGap];
/// only the gap above the checkout section may exceed the maximum, and only
/// once every other gap is at the maximum; a scrolling panel has minimum gaps.
void _expectSpacing(WidgetTester tester, Size size) {
  final sm = AppMetrics(size).summary;
  final blocks = <String, Rect>{
    'title': tester.getRect(
      find
          .ancestor(
            of: find.text('Bill Summary'),
            matching: find.byType(SizedBox),
          )
          .first,
    ),
    'totals': tester.getRect(find.byType(TotalsCard)),
    'forex': tester.getRect(find.byType(ForexCard)),
    'member': tester.getRect(find.byType(MemberCard)),
    'checkout': tester.getRect(find.byType(PaymentSection)),
    'quick': tester.getRect(find.byType(QuickActionsGrid)),
  };
  final names = blocks.keys.toList();
  final scrollable = tester.state<ScrollableState>(
    find
        .descendant(
          of: find.byType(BillSummaryBody),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  final scrolls = scrollable.position.maxScrollExtent > 0.5;
  for (var i = 0; i < names.length - 1; i++) {
    final gap = blocks[names[i + 1]]!.top - blocks[names[i]]!.bottom;
    final why = '${names[i]} -> ${names[i + 1]} gap $gap at $size';
    expect(gap, greaterThanOrEqualTo(sm.baseGap - 0.5), reason: 'min: $why');
    if (scrolls) {
      expect(gap, closeTo(sm.baseGap, 0.5), reason: 'scrolling: $why');
    } else if (i != BillSummaryBody.memberIndex) {
      expect(
        gap,
        lessThanOrEqualTo(SummaryMetrics.maxCardGap + 0.5),
        reason: 'max: $why',
      );
    }
  }
  if (!scrolls) {
    final auto =
        blocks['checkout']!.top - blocks['member']!.bottom; // may be larger
    if (auto > SummaryMetrics.maxCardGap + 0.5) {
      for (var i = 0; i < names.length - 1; i++) {
        if (i == BillSummaryBody.memberIndex) continue;
        final gap = blocks[names[i + 1]]!.top - blocks[names[i]]!.bottom;
        expect(
          gap,
          closeTo(SummaryMetrics.maxCardGap, 0.5),
          reason: 'slack goes to the middle only after the others are full',
        );
      }
    }
  }
}

/// The rate and tendered inputs have room for their text line.
void _expectNoClippedInputs(WidgetTester tester, Size size) {
  final sm = AppMetrics(size).summary;
  final rate = tester.getSize(
    find.descendant(
      of: find.byType(ForexCard),
      matching: find.byType(TextField),
    ),
  );
  expect(
    rate.height,
    greaterThanOrEqualTo(sm.rateFont * SummaryMetrics.inputLineHeight - 0.01),
    reason: 'rate input $rate at $size',
  );
  final box = find.descendant(
    of: find.byType(CashPanel),
    matching: find.byType(AppInputBox),
  );
  final tendered = tester.getSize(
    find.descendant(of: box, matching: find.byType(TextField)),
  );
  expect(
    tendered.height,
    greaterThanOrEqualTo(
      sm.tenderedFont * SummaryMetrics.inputLineHeight - 0.01,
    ),
    reason: 'tendered text box $tendered at $size',
  );
  expect(tester.getSize(box).height, sm.tenderedHeight);
}

/// Every card keeps [SummaryMetrics.minCardInset] between its border and the
/// visible content (text, inputs, buttons, the rate underline).
void _expectInnerPadding(WidgetTester tester, Size size, {String? mode}) {
  final cards = <String, Type>{
    'totals': TotalsCard,
    'forex': ForexCard,
    'member': MemberCard,
    'checkout': PaymentSection,
  };
  cards.forEach((name, type) {
    final card = tester.getRect(find.byType(type));
    final content = cardContentRect(tester, find.byType(type), SummaryCard);
    expectInset(
      card,
      content,
      SummaryMetrics.minCardInset,
      reason: '$name ${mode ?? ''} card $card content $content at $size',
    );
  });
}

/// Label to input and row to row gaps inside the member and payment cards.
void _expectInnerGaps(WidgetTester tester, Size size) {
  const label = SummaryMetrics.minLabelGap;
  const row = SummaryMetrics.minRowGap;
  Rect text(String t) => tester.getRect(find.text(t).first);
  Rect box(String t) => tester.getRect(
    find
        .ancestor(of: find.text(t).first, matching: find.byType(Container))
        .first,
  );
  final member = find.byType(MemberCard);
  final memberRects = paintRects(member.evaluate().first);
  final memberRect = tester.getRect(member);
  if (!AppMetrics(size).heightAtMost719) {
    for (final name in <String>[
      'Member Ship No.',
      'Membership Info.',
      'Available Points',
      'Redeem Points',
    ]) {
      final l = text(name);
      // The input of this label: the topmost box under it in its column.
      final below =
          memberRects
              .where(
                (r) =>
                    r.top >= l.bottom - 0.01 &&
                    r.left < l.right &&
                    r.right > l.left &&
                    r.height > l.height,
              )
              .toList()
            ..sort((a, b) => a.top.compareTo(b.top));
      expect(below, isNotEmpty, reason: 'input under $name at $size');
      expectGap(l, below.first, label, reason: 'label $name at $size');
    }
    // Row 1 inputs to the row 2 labels.
    final firstRowBottom = memberRects
        .where((r) => r.bottom <= text('Available Points').top + 0.01)
        .map((r) => r.bottom)
        .reduce((a, b) => a > b ? a : b);
    expect(
      text('Available Points').top - firstRowBottom,
      greaterThanOrEqualTo(row - 0.01),
      reason: 'member rows at $size $memberRect',
    );
  }
  final cash = box('Cash');
  final due = text('Amount Due');
  final tendered = tester.getRect(
    find.descendant(
      of: find.byType(CashPanel),
      matching: find.byType(AppInputBox),
    ),
  );
  final exact = box('Exact');
  final change = text('Change Due');
  final complete = box('Complete Payment');
  expectGap(cash, due, row, reason: 'buttons -> due at $size');
  expectGap(due, tendered, row, reason: 'due -> tendered at $size');
  expectGap(tendered, exact, row, reason: 'tendered -> quick at $size');
  expectGap(exact, change, row, reason: 'quick -> change at $size');
  expectGap(change, complete, row, reason: 'change -> complete at $size');
}

/// With the tendered field focused the text keeps at least
/// [SummaryMetrics.minRingClearance] from the focus ring on every side.
Future<void> _expectRingClearance(WidgetTester tester, Size size) async {
  final pay = Get.find<PaymentController>();
  pay.tendered.text = '47.20';
  pay.tenderedFocus.requestFocus();
  await tester.pump();
  final outline = find.descendant(
    of: find.byType(CashPanel),
    matching: find.byType(FocusOutline),
  );
  final box = tester.getRect(outline);
  final ringInner = box.inflate(AppSizes.focusRingOffset);
  RenderEditable? editable;
  void visit(Element e) {
    if (e.renderObject is RenderEditable) {
      editable = e.renderObject! as RenderEditable;
    }
    e.visitChildren(visit);
  }

  visit(outline.evaluate().first);
  final r = editable!;
  final boxes = r.getBoxesForSelection(
    const TextSelection(baseOffset: 0, extentOffset: 5),
  );
  final origin = r.localToGlobal(Offset.zero);
  var text = boxes.first.toRect().shift(origin);
  for (final b in boxes.skip(1)) {
    text = text.expandToInclude(b.toRect().shift(origin));
  }
  // The painted line box is the strut: the full editable height at most.
  final line = Rect.fromLTRB(
    text.left,
    r.localToGlobal(Offset(0, (r.size.height - r.preferredLineHeight) / 2)).dy,
    text.right,
    r.localToGlobal(Offset(0, (r.size.height + r.preferredLineHeight) / 2)).dy,
  );
  const min = SummaryMetrics.minRingClearance;
  final why = 'text $line ring $ringInner box $box at $size';
  expect(
    line.top - ringInner.top,
    greaterThanOrEqualTo(min - 0.01),
    reason: 'top $why',
  );
  expect(
    ringInner.bottom - line.bottom,
    greaterThanOrEqualTo(min - 0.01),
    reason: 'bottom $why',
  );
  expect(
    line.left - ringInner.left,
    greaterThanOrEqualTo(min - 0.01),
    reason: 'left $why',
  );
  pay.tenderedFocus.unfocus();
  await tester.pump();
}
