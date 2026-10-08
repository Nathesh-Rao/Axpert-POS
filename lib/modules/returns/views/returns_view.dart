import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_management_sizes.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/qty_formatter.dart';
import '../../../shared/widgets/management_page.dart';
import '../../../shared/widgets/modal_primary_button.dart';
import '../../shell/views/app_shell.dart';
import '../controllers/returns_controller.dart';
import '../services/refund_service.dart';
import '../widgets/return_line.dart';

/// `/returns`: find a bill by its number, type the quantities to take back and
/// "Refund & restock". Quirks of the prototype are kept (KG-164 onward).
class ReturnsView extends GetView<ReturnsController> {
  const ReturnsView({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final title = context.text
        .of(AppFontSize.s13, height: AppLineHeight.base)
        .copyWith(color: c.text);
    final muted = context.text
        .of(AppFontSize.s13, height: AppLineHeight.base)
        .copyWith(color: c.muted);
    return AppShell(
      page: AppPage.returns,
      child: ManagementPage(
        title: s.navReturns(),
        slivers: <Widget>[
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: context.metrics.managementPad,
            ),
            sliver: SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppManagementSizes.returnsMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppManagementSizes.returnsTitleMarginBottom,
                        ),
                        child: Text(s.returnsFindTitle(), style: title),
                      ),
                      ManagementSearch(
                        controller: controller.billNumber,
                        hint: s.returnsBillHint(),
                        onChanged: controller.onBillChanged,
                      ),
                      _Result(controller: controller, muted: muted),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.controller, required this.muted});

  final ReturnsController controller;
  final TextStyle muted;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    const gap = EdgeInsets.symmetric(
      vertical: AppManagementSizes.returnsParagraphMarginY,
    );
    return Obx(() {
      final sale = controller.sale.value;
      if (sale == null) {
        return Padding(
          padding: gap,
          child: Text(
            controller.text.value.isNotEmpty
                ? s.returnsNoMatch()
                : s.returnsBegin(),
            style: muted,
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: gap,
            child: Text(
              s.returnsBillSummary(
                sale.customer,
                MoneyFormatter.format(sale.totals.total),
              ),
              style: muted,
            ),
          ),
          for (final line in sale.cart.lines)
            ReturnLine(
              key: ValueKey<String>('${sale.number}/${line.product.id}'),
              name: line.product.name,
              available: QtyFormatter.compact(
                RefundService.available(sale, line),
              ),
              controller: controller.fieldFor(line.product.id),
              onChanged: (value) =>
                  controller.onQtyChanged(line.product.id, value),
            ),
          ModalPrimaryButton(
            label: s.returnsRefundButton(),
            marginTop: AppManagementSizes.returnsButtonMarginTop,
            onTap: controller.refund,
          ),
        ],
      );
    });
  }
}
