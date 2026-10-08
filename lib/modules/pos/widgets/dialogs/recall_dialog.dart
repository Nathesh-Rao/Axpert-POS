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
import '../../../../shared/widgets/app_pressable.dart';
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
    // `.modal-list{max-height:min(400px,40dvh)}`
    final maxHeight = [
      AppCheckoutSizes.modalListMaxHeight,
      MediaQuery.sizeOf(context).height *
          AppCheckoutSizes.modalListMaxHeightFraction,
    ].reduce((a, b) => a < b ? a : b);
    final rowStyle = context.text.of(
      AppFontSize.s14,
      weight: AppFontWeight.bold,
      height: AppLineHeight.base,
    );
    return Obx(() {
      final bills = held.bills.toList();
      Widget row(HeldBill bill) {
        final total = cart.totalsOf(bill.cart).total;
        return AppPressable(
          semanticLabel: s.heldBillRowTitle(bill.ref, bill.cart.lines.length),
          onTap: () => flow.pick(bill),
          builder: (context, hovered) => Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppCheckoutSizes.modalListRowPadY,
              horizontal: AppCheckoutSizes.modalListRowPadX,
            ),
            decoration: BoxDecoration(
              color: hovered ? c.secondary : null,
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  AppIcons.pauseCircle,
                  size: AppCheckoutSizes.modalListIcon,
                  color: c.text,
                ),
                const SizedBox(width: AppCheckoutSizes.modalListRowGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        s.heldBillRowTitle(bill.ref, bill.cart.lines.length),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: rowStyle.copyWith(color: c.text),
                      ),
                      const SizedBox(
                        height: AppCheckoutSizes.modalListSmallMarginTop,
                      ),
                      Text(
                        DateFormatter.dateTime(
                          DateTime.parse(bill.time).toLocal(),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text
                            .fluid(AppCheckoutSizes.modalListSmallFont)
                            .copyWith(color: c.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppCheckoutSizes.modalListRowGap),
                Text(
                  MoneyFormatter.format(total),
                  maxLines: 1,
                  softWrap: false,
                  style: rowStyle.copyWith(color: c.text),
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppCheckoutSizes.modalListMarginY,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[for (final bill in bills) row(bill)],
                  ),
                ),
              ),
            ),
          ),
          if (bills.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppCheckoutSizes.emptyStatePadY,
                horizontal: AppCheckoutSizes.emptyStatePadX,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    AppIcons.fileText,
                    size: AppCheckoutSizes.emptyStateIcon,
                    color: c.muted,
                  ),
                  const SizedBox(height: AppCheckoutSizes.emptyStateGap),
                  Text(
                    s.heldBillsEmpty(),
                    textAlign: TextAlign.center,
                    style: context.text
                        .of(AppFontSize.s14, height: AppLineHeight.base)
                        .copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}
