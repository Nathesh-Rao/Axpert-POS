import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_management_sizes.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/widgets/app_data_table.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../../../shared/widgets/management_page.dart';
import '../../shell/views/app_shell.dart';
import '../controllers/sales_page_controller.dart';
import '../models/sale.dart';

/// `/sales`: the ledger, newest first, with "View receipt" per bill.
class SalesView extends GetView<SalesPageController> {
  const SalesView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final pad = context.metrics.managementPad;
    return AppShell(
      page: AppPage.sales,
      child: ManagementPage(
        title: s.navSales(),
        search: ManagementSearch(
          controller: controller.filterText,
          hint: s.searchPageHint(s.pageNameSales()),
          onChanged: controller.onFilterChanged,
        ),
        slivers: <Widget>[
          Obx(() {
            final rows = controller.rows;
            return AppDataTable(
              padding: EdgeInsets.symmetric(horizontal: pad),
              columns: <TableColumnSpec>[
                TableColumnSpec(label: s.colBill(), flex: 206),
                TableColumnSpec(label: s.colDate(), flex: 240),
                TableColumnSpec(label: s.colCustomer(), flex: 374),
                TableColumnSpec(label: s.colMode(), flex: 267),
                TableColumnSpec(label: s.colTotal(), flex: 190),
                const TableColumnSpec(label: '', flex: 181),
              ],
              rowCount: rows.length,
              cellsOf: (context, i) {
                final sale = rows[i];
                return <Widget>[
                  TableText(sale.number, oneLine: true),
                  TableText(
                    DateFormatter.dateTimeComma(
                      DateTime.parse(sale.date).toLocal(),
                    ),
                    oneLine: true,
                  ),
                  TableText(sale.customer),
                  TableText(sale.mode, oneLine: true),
                  TableText(
                    MoneyFormatter.format(sale.totals.total),
                    oneLine: true,
                  ),
                  _ViewReceipt(sale: sale),
                ];
              },
            );
          }),
          SliverToBoxAdapter(
            child: Obx(
              () => controller.source.isEmpty
                  ? const _EmptySales()
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.text-button` "View receipt": opens the receipt of this sale.
class _ViewReceipt extends StatelessWidget {
  const _ViewReceipt({required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPressable(
      borderRadius: 4,
      onTap: () => Get.find<OverlayController>().open('receipt', payload: sale),
      builder: (context, hovered) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          context.strings.salesViewReceipt(),
          maxLines: 1,
          softWrap: false,
          style: context.text
              .fluid(AppManagementSizes.tdFont, height: AppLineHeight.base)
              .copyWith(color: c.blue),
        ),
      ),
    );
  }
}

/// `.empty-state`: the document icon, the title and the hint.
class _EmptySales extends StatelessWidget {
  const _EmptySales();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final style = context.text
        .of(AppFontSize.s13, height: AppLineHeight.base)
        .copyWith(color: c.muted);
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppCheckoutSizes.emptyStatePadY,
        horizontal: AppCheckoutSizes.emptyStatePadX,
      ),
      child: Column(
        children: <Widget>[
          Icon(
            AppIcons.fileText,
            size: AppManagementSizes.salesEmptyIcon,
            color: c.muted,
          ),
          const SizedBox(height: AppCheckoutSizes.emptyStateGap),
          Text(s.salesEmptyTitle(), textAlign: TextAlign.center, style: style),
          const SizedBox(height: AppCheckoutSizes.emptyStateGap),
          Text(s.salesEmptyBody(), textAlign: TextAlign.center, style: style),
        ],
      ),
    );
  }
}
