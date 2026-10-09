import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_management_sizes.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/management_page.dart';
import '../../shell/views/app_shell.dart';
import '../../shift/services/shift_summary.dart';
import '../controllers/reports_controller.dart';
import '../widgets/report_bar.dart';
import '../widgets/report_stat.dart';

/// `/reports`: today's sales, bills and average, and the bars by mode. Every
/// figure comes from [ShiftSummary].
class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final pad = context.metrics.managementPad;
    // Created here, in plain build code: creating it inside the Obx builder
    // would run its onInit under an observer (and any write in it during the
    // build of that Obx).
    final reports = controller;
    final body = context.text
        .of(AppFontSize.s13, height: AppLineHeight.base)
        .copyWith(color: c.text);
    return AppShell(
      page: AppPage.reports,
      child: ManagementPage(
        title: s.navReports(),
        slivers: <Widget>[
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: pad),
            sliver: SliverToBoxAdapter(
              child: Obx(() {
                final today = reports.summary.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // The heading's 28 px margin collapses with the stats'
                    // 30 px in CSS: only the difference is added here.
                    const SizedBox(
                      height:
                          AppManagementSizes.reportStatsMarginTop -
                          AppManagementSizes.headingMarginBottom,
                    ),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                            child: ReportStat(
                              label: s.reportsTodaySales(),
                              value: MoneyFormatter.format(today.total),
                            ),
                          ),
                          const SizedBox(
                            width: AppManagementSizes.reportStatsGap,
                          ),
                          Expanded(
                            child: ReportStat(
                              label: s.reportsBillsCompleted(),
                              value: s.countBadge(today.count),
                            ),
                          ),
                          const SizedBox(
                            width: AppManagementSizes.reportStatsGap,
                          ),
                          Expanded(
                            child: ReportStat(
                              label: s.reportsAverageBill(),
                              value: MoneyFormatter.format(today.average),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: AppManagementSizes.reportStatsMarginBottom,
                    ),
                    Text(s.reportsByMode(), style: body),
                    const SizedBox(height: AppManagementSizes.chartMarginY),
                    for (var i = 0; i < ShiftSummary.modes.length; i++) ...[
                      if (i > 0)
                        const SizedBox(
                          height: AppManagementSizes.chartRowMarginY,
                        ),
                      ReportBar(
                        label: ShiftSummary.modes[i],
                        basisPoints: today.barBasisPoints(
                          today.byMode(ShiftSummary.modes[i]),
                        ),
                        amount: MoneyFormatter.format(
                          today.byMode(ShiftSummary.modes[i]),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppManagementSizes.chartMarginY),
                    Text(
                      s.reportsBasedOn(DateFormatter.date(today.day)),
                      style: body.copyWith(color: c.muted),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
