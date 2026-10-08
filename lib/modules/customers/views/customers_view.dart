import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_management_sizes.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/widgets/app_data_table.dart';
import '../../../shared/widgets/management_page.dart';
import '../../../shared/widgets/modal_primary_button.dart';
import '../../shell/views/app_shell.dart';
import '../controllers/customers_page_controller.dart';

/// `/customers`: the read-only customer table and the Add Customer button
/// (the dialog is the one built in S4.c).
class CustomersView extends GetView<CustomersPageController> {
  const CustomersView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return AppShell(
      page: AppPage.customers,
      child: ManagementPage(
        title: s.navCustomers(),
        action: ModalPrimaryButton(
          label: s.customerAddButton(),
          icon: AppIcons.plus,
          iconSize: 18,
          onTap: () => Get.find<OverlayController>().open('addCustomer'),
        ),
        search: ManagementSearch(
          controller: controller.filterText,
          hint: s.searchPageHint(s.pageNameCustomers()),
          onChanged: controller.onFilterChanged,
        ),
        slivers: <Widget>[
          Obx(() {
            final rows = controller.rows;
            String orDash(String value) =>
                value.isEmpty ? s.emptyCell() : value;
            return AppDataTable(
              padding: EdgeInsets.symmetric(
                horizontal: context.metrics.managementPad,
              ),
              columns: <TableColumnSpec>[
                TableColumnSpec(
                  label: s.colName(),
                  flex: 353,
                  minContent: AppManagementSizes.customersMinName,
                ),
                TableColumnSpec(
                  label: s.colPhone(),
                  flex: 271,
                  minContent: AppManagementSizes.customersMinPhone,
                ),
                TableColumnSpec(
                  label: s.colEmail(),
                  flex: 436,
                  minContent: AppManagementSizes.customersMinEmail,
                ),
                TableColumnSpec(
                  label: s.colMembership(),
                  flex: 241,
                  minContent: AppManagementSizes.customersMinMembership,
                ),
                TableColumnSpec(
                  label: s.colPoints(),
                  flex: 157,
                  minContent: AppManagementSizes.customersMinPoints,
                ),
              ],
              rowCount: rows.length,
              cellsOf: (context, i) {
                final c = rows[i];
                return <Widget>[
                  TableText(c.name),
                  TableText(orDash(c.phone), oneLine: true),
                  TableText(orDash(c.email), ellipsis: true),
                  TableText(orDash(c.member), oneLine: true),
                  TableText(s.countBadge(c.points), oneLine: true),
                ];
              },
            );
          }),
        ],
      ),
    );
  }
}
