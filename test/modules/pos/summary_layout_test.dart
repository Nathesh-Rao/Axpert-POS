// The Bill Summary and the cart panel across window sizes (width 1000 to 1900,
// height 600 to 1000): flutter_test fails on any RenderFlex error, and key
// texts are measured (one line, no per-character wrapping, inside the
// window). Runs on VM and Chrome.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';
import 'package:pos_application/core/responsive/summary_metrics.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
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
