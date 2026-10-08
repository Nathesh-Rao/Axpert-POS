import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/decimal_text.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_data_table.dart';
import '../../../shared/widgets/management_page.dart';
import '../../shell/views/app_shell.dart';
import '../controllers/products_page_controller.dart';

/// `/products`: the read-only product table (no add, edit or sort: KG-021).
class ProductsView extends GetView<ProductsPageController> {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    return AppShell(
      page: AppPage.products,
      child: ManagementPage(
        title: s.navProducts(),
        search: ManagementSearch(
          controller: controller.filterText,
          hint: s.searchPageHint(s.pageNameProducts()),
          onChanged: controller.onFilterChanged,
        ),
        slivers: <Widget>[
          Obx(() {
            final rows = controller.rows;
            return AppDataTable(
              padding: EdgeInsets.symmetric(
                horizontal: context.metrics.managementPad,
              ),
              columns: <TableColumnSpec>[
                TableColumnSpec(label: s.colProduct(), flex: 442),
                TableColumnSpec(label: s.colCodeBarcode(), flex: 262),
                TableColumnSpec(label: s.colCategory(), flex: 263),
                TableColumnSpec(label: s.colGst(), flex: 119),
                TableColumnSpec(label: s.colPrice(), flex: 177),
                TableColumnSpec(label: s.colStock(), flex: 167),
              ],
              rowCount: rows.length,
              cellsOf: (context, i) {
                final p = rows[i];
                return <Widget>[
                  TableText(p.name),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      TableText(p.code, oneLine: true),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          p.barcode,
                          softWrap: false,
                          maxLines: 1,
                          style: context.text
                              .of(AppFontSize.s12, height: AppLineHeight.base)
                              .copyWith(color: c.muted),
                        ),
                      ),
                    ],
                  ),
                  TableText(p.category),
                  TableText(
                    s.percentSuffix(DecimalText.scaled(p.gst.value, 2)),
                    oneLine: true,
                  ),
                  TableText(MoneyFormatter.format(p.price), oneLine: true),
                  StockChip(stock: p.stock),
                ];
              },
            );
          }),
        ],
      ),
    );
  }
}
