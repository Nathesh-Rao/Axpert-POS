import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/responsive/app_metrics_scope.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../session/presentation/controllers/active_session.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/decimal_text.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/app_data_table.dart';
import '../../../../shared/widgets/management_page.dart';
import '../../../../modules/shell/views/app_shell.dart';
import '../../../../core/theme/tokens/app_icons.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../shared/widgets/kbd_chip.dart';
import '../../../../shared/widgets/modal_primary_button.dart';
import '../../domain/entities/product.dart';
import '../controllers/product_admin_controller.dart';
import '../controllers/products_page_controller.dart';
import '../stock_text.dart';
import '../widgets/product_form_parts.dart';

/// `/products`: the product table. Admins and managers also get add, edit,
/// deactivate and stock adjustment (DEC-152); there is still no sort (KG-021).
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
        action: controller.admin.canManage
            ? _ManageActions(admin: controller.admin)
            : null,
        search: ManagementSearch(
          controller: controller.filterText,
          hint: s.searchPageHint(s.pageNameProducts()),
          onChanged: controller.onFilterChanged,
        ),
        slivers: <Widget>[
          Obx(() {
            final admin = controller.admin;
            // Read here so the table follows these changes.
            admin.revision.value;
            final stock = admin.stock;
            final manage = admin.canManage;
            final inactive = controller.inactiveRows;
            final rows = <Product>[...controller.rows, ...inactive];
            final inactiveIds = {for (final p in inactive) p.id};
            return AppDataTable(
              padding: EdgeInsets.symmetric(
                horizontal: context.metrics.managementPad,
              ),
              columns: <TableColumnSpec>[
                TableColumnSpec(label: s.colProduct(), flex: 442),
                TableColumnSpec(label: s.colCodeBarcode(), flex: 262),
                TableColumnSpec(label: s.colCategory(), flex: 263),
                TableColumnSpec(
                  label: s.colTax(Get.find<ActiveSession>().taxLabel),
                  flex: 119,
                ),
                TableColumnSpec(label: s.colPrice(), flex: 177),
                TableColumnSpec(label: s.colStock(), flex: 167),
                if (manage)
                  TableColumnSpec(label: s.colProductActions(), flex: 230),
              ],
              rowCount: rows.length,
              cellsOf: (context, i) {
                final p = rows[i];
                final off = inactiveIds.contains(p.id);
                final view = stock[p.id];
                return <Widget>[
                  TableText(p.name, color: off ? c.muted : null),
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
                  if (off)
                    TableText(s.productInactiveBadge(), color: c.muted)
                  else
                    StockChip(
                      stock: p.stock,
                      label: view == null
                          ? null
                          : stockText(
                              s,
                              view.balanceMilli,
                              view.levels,
                              view.baseUnitName,
                            ),
                    ),
                  if (manage) _RowActions(admin: admin, product: p, off: off),
                ];
              },
            );
          }),
        ],
      ),
    );
  }
}

/// The heading's right side: the inactive switch and "Add product" with its
/// shortcut hint.
class _ManageActions extends StatelessWidget {
  const _ManageActions({required this.admin});

  final ProductAdminController admin;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final mac = Theme.of(context).platform == TargetPlatform.macOS;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Obx(
          () => OnOffToggle(
            label: s.productShowInactive(),
            value: admin.showInactive.value,
            onChanged: (v) => admin.showInactive.value = v,
          ),
        ),
        const SizedBox(width: AppSpacing.s16),
        KbdChip(mac ? s.newProductShortcutMac() : s.newProductShortcutOther()),
        const SizedBox(width: AppSpacing.s8),
        ModalPrimaryButton(
          label: s.productAddButton(),
          icon: AppIcons.plus,
          iconSize: 18,
          onTap: admin.openAdd,
        ),
      ],
    );
  }
}

/// Edit and Deactivate (or Reactivate) of one row.
class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.admin,
    required this.product,
    required this.off,
  });

  final ProductAdminController admin;
  final Product product;
  final bool off;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return Wrap(
      spacing: AppSpacing.s8,
      children: <Widget>[
        if (off)
          FormTextButton(
            label: s.productReactivateAction(),
            onTap: () => admin.reactivate(product),
          )
        else ...<Widget>[
          FormTextButton(
            label: s.productEditAction(),
            onTap: () => admin.openEdit(product),
          ),
          FormTextButton(
            label: s.productDeactivateAction(),
            onTap: () => admin.confirmDeactivate(product),
          ),
        ],
      ],
    );
  }
}
