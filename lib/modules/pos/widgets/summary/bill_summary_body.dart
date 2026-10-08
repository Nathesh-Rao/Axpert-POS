import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../../../../core/responsive/app_metrics_scope.dart';
import '../../../../core/responsive/summary_metrics.dart';
import 'forex_card.dart';
import 'member_card.dart';
import 'payment_section.dart';
import 'quick_actions_grid.dart';
import 'summary_column.dart';
import 'totals_card.dart';

/// Everything of the Bill Summary: title, totals, conversion, member card,
/// checkout section and quick actions, stacked by [SummaryColumn]. Gaps are at
/// least 8 px, free height spreads over the gaps up to 16 px and the rest
/// collects above the checkout section; content taller than the panel scrolls
/// (no visible scrollbar, as in the prototype). User-approved deviation from
/// the media-rule gaps of 3 to 4 px (DEC-099).
class BillSummaryBody extends StatelessWidget {
  const BillSummaryBody({required this.title, super.key});

  /// Index of the member card: the gap after it is the `margin-top:auto` one.
  static const int memberIndex = 3;

  final Widget title;

  @override
  Widget build(BuildContext context) {
    final sm = context.metrics.summary;
    return LayoutBuilder(
      builder: (context, constraints) => ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
          dragDevices: <PointerDeviceKind>{
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: SingleChildScrollView(
          child: SummaryColumn(
            availableHeight: constraints.maxHeight,
            minGap: sm.baseGap,
            maxGap: SummaryMetrics.maxCardGap,
            autoGapIndex: memberIndex,
            children: <Widget>[
              title,
              const TotalsCard(),
              const ForexCard(),
              const MemberCard(),
              const PaymentSection(),
              const QuickActionsGrid(),
            ],
          ),
        ),
      ),
    );
  }
}
