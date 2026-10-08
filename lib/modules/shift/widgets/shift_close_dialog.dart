import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_management_sizes.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/modal_info_row.dart';
import '../../../shared/widgets/modal_primary_button.dart';
import '../../pos/services/checkout_service.dart';
import '../controllers/shift_controller.dart';

/// `modal === "close"`: the shift at a glance (total, Cash, Card, bills; Credit
/// has no row, KG-159) and "Confirm & close counter".
class ShiftCloseDialog extends StatelessWidget {
  const ShiftCloseDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final shift = Get.find<ShiftController>();
    final today = shift.today;
    return AppModal(
      leading: const ModalSymbol(
        icon: AppIcons.power,
        iconSize: AppManagementSizes.closeSymbolIcon,
      ),
      title: s.closeTitle(),
      scrollable: true,
      children: <Widget>[
        ModalParagraph(s.closeIntro()),
        ModalInfoRow(
          label: s.closeTotalSales(),
          value: MoneyFormatter.format(today.total),
        ),
        ModalInfoRow(
          label: s.payCash(),
          value: MoneyFormatter.format(today.byMode(SaleMode.cash)),
        ),
        ModalInfoRow(
          label: s.payCard(),
          value: MoneyFormatter.format(today.byMode(SaleMode.card)),
        ),
        ModalInfoRow(label: s.closeBills(), value: s.countBadge(today.count)),
        ModalParagraph(s.closeNote()),
        ModalPrimaryButton(
          label: s.closeConfirm(),
          marginTop: AppCheckoutSizes.primaryFullMarginTop,
          onTap: shift.closeCounter,
        ),
      ],
    );
  }
}
