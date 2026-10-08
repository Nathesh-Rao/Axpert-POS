import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/responsive/app_metrics_scope.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../core/theme/tokens/app_icons.dart';
import '../../controllers/payment_controller.dart';
import '../../models/payment_state.dart';
import 'card_panel.dart';
import 'cash_panel.dart';
import 'pay_button.dart';
import 'summary_card.dart';

/// `.checkout-section`: Cash / Card buttons and the inline payment panel.
class PaymentSection extends StatelessWidget {
  const PaymentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final sm = m.summary;
    final s = context.strings;
    final pay = Get.find<PaymentController>();
    return SummaryCard(
      padding: sm.checkoutPad,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Obx(() {
            final canPay = pay.canPay;
            final credit = pay.isCredit;
            final mode = pay.mode.value;
            return Row(
              children: <Widget>[
                Expanded(
                  child: PayButton(
                    label: credit ? s.paySaveCredit() : s.payCash(),
                    icon: AppIcons.banknote,
                    tone: PayTone.cash,
                    pressed: mode == PaymentMode.cash,
                    height: sm.paymentButtonHeight,
                    fontSize: sm.paymentButtonFont,
                    onTap: canPay ? () => pay.payment(PaymentMode.cash) : null,
                  ),
                ),
                const SizedBox(width: AppCheckoutSizes.payButtonGap),
                Expanded(
                  child: PayButton(
                    label: s.payCard(),
                    icon: AppIcons.creditCard,
                    tone: PayTone.card,
                    pressed: mode == PaymentMode.card,
                    height: sm.paymentButtonHeight,
                    fontSize: sm.paymentButtonFont,
                    onTap: canPay && !credit
                        ? () => pay.payment(PaymentMode.card)
                        : null,
                  ),
                ),
              ],
            );
          }),
          SizedBox(height: sm.checkoutGap),
          Obx(
            () => pay.mode.value == PaymentMode.cash
                ? const CashPanel()
                : const CardPanel(),
          ),
        ],
      ),
    );
  }
}
