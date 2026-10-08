import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../core/theme/tokens/app_icons.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/app_modal.dart';
import '../../../../shared/widgets/modal_list_row.dart';
import '../../../../shared/widgets/modal_list_view.dart';
import '../../../../shared/widgets/modal_actions.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/held_bills_controller.dart';
import '../../controllers/hold_recall_controller.dart';
import '../../models/held_bill.dart';

/// F5 / Recall: the held bills, or (after picking one while a cart is active)
/// the "You have an active cart" question, in the same modal like the
/// prototype's `recallPending`.
class RecallDialog extends StatelessWidget {
  const RecallDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final flow = Get.find<HoldRecallController>();
    return Obx(() {
      final pending = flow.pending.value;
      if (pending != null) {
        return AppModal(
          title: s.recallConflictTitle(),
          children: <Widget>[
            ModalParagraph(s.recallConflictBody(pending.ref)),
            ModalActions(
              secondaryLabel: s.recallReplaceCurrent(),
              onSecondary: flow.replaceCurrent,
              primaryLabel: s.recallHoldAndRecall(),
              onPrimary: flow.holdAndRecall,
            ),
          ],
        );
      }
      return AppModal(
        title: s.heldBillsTitle(),
        children: <Widget>[
          ModalParagraph(s.heldBillsSubtitle()),
          const _HeldList(),
        ],
      );
    });
  }
}

class _HeldList extends StatelessWidget {
  const _HeldList();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final held = Get.find<HeldBillsController>();
    final flow = Get.find<HoldRecallController>();
    final cart = Get.find<CartController>();
    final rowStyle = context.text.of(
      AppFontSize.s14,
      weight: AppFontWeight.bold,
      height: AppLineHeight.base,
    );
    return Obx(() {
      final bills = held.bills.toList();
      Widget row(HeldBill bill) {
        final total = cart.totalsOf(bill.cart).total;
        return ModalListRow(
          key: ObjectKey(bill),
          icon: AppIcons.pauseCircle,
          iconSize: AppCheckoutSizes.modalListIcon,
          title: s.heldBillRowTitle(bill.ref, bill.cart.lines.length),
          subtitle: DateFormatter.dateTime(DateTime.parse(bill.time).toLocal()),
          onTap: () => flow.pick(bill),
          trailing: Text(
            MoneyFormatter.format(total),
            maxLines: 1,
            softWrap: false,
            style: rowStyle.copyWith(color: c.text),
          ),
        );
      }

      return ModalListView(
        rows: <Widget>[for (final bill in bills) row(bill)],
        emptyText: s.heldBillsEmpty(),
      );
    });
  }
}
