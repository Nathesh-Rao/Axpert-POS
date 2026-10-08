import 'package:flutter/material.dart';

import '../../../../core/responsive/app_metrics_scope.dart';
import 'forex_card.dart';
import 'member_card.dart';
import 'payment_section.dart';
import 'quick_actions_grid.dart';
import 'totals_card.dart';

/// Everything below the Bill Summary title: totals, conversion, member card,
/// the checkout section (pushed to the bottom, `margin-top:auto`) and the
/// quick actions. Like the prototype's `overflow:hidden` panel, content that
/// does not fit is clipped, never scrolled.
class BillSummaryBody extends StatelessWidget {
  const BillSummaryBody({required this.title, super.key});

  final Widget title;

  @override
  Widget build(BuildContext context) {
    final gap = context.metrics.summary.gap;
    return LayoutBuilder(
      builder: (context, constraints) => ClipRect(
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    title,
                    SizedBox(height: gap),
                    const TotalsCard(),
                    SizedBox(height: gap),
                    const ForexCard(),
                    SizedBox(height: gap),
                    const MemberCard(),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: gap),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const PaymentSection(),
                      SizedBox(height: gap),
                      const QuickActionsGrid(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
