import 'package:flutter/material.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/app_panel.dart';
import '../../pos/widgets/summary/bill_summary_body.dart';
import '../../../core/theme/tokens/app_icons.dart';

/// The right-hand Bill Summary panel: title plus the checkout cards (S4.a).
/// Width: 380 on POS, 310 elsewhere (KG-029).
class BillSummaryFrame extends StatelessWidget {
  const BillSummaryFrame({required this.isPos, super.key});

  final bool isPos;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    return SizedBox(
      width: m.summaryWidth(isPos: isPos),
      child: AppPanel(
        padding: EdgeInsets.all(m.billSummaryPad),
        child: BillSummaryBody(
          title: SizedBox(
            height: m.summary.titleHeight,
            child: Row(
              children: <Widget>[
                Icon(AppIcons.fileText, size: 23, color: c.blue),
                const SizedBox(width: AppSpacing.s12),
                Flexible(
                  child: Text(
                    context.strings.billSummaryTitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text
                        .fluid(
                          m.billSummaryTitleFont,
                          weight: AppFontWeight.bold,
                          height: AppLineHeight.summaryTitle,
                        )
                        .copyWith(color: c.text),
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
