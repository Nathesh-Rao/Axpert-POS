import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/responsive/app_metrics_scope.dart';
import '../../../../core/responsive/summary_metrics.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../core/theme/tokens/app_icons.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/app_pressable.dart';
import '../../../../shared/widgets/app_spinner.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/payment_controller.dart';
import '../../models/payment_state.dart';
import 'complete_button.dart';

/// Card inline payment: the simulated terminal, the decline toggle with Retry
/// and the Complete button.
class CardPanel extends StatelessWidget {
  const CardPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final sm = context.metrics.summary;
    final s = context.strings;
    final c = context.colors;
    final pay = Get.find<PaymentController>();
    final cart = Get.find<CartController>();
    final small = sm.density != SummaryDensity.normal;
    return Obx(() {
      final active = cart.active.value;
      final state = pay.terminal.value;
      final color = switch (state) {
        TerminalState.waiting => c.blue,
        TerminalState.approved => c.terminalApproved,
        TerminalState.declined => c.terminalDeclined,
      };
      final text = !active
          ? s.terminalAddItems()
          : switch (state) {
              TerminalState.waiting => s.terminalWaiting(),
              TerminalState.approved => s.terminalApproved(),
              TerminalState.declined => s.terminalDeclined(),
            };
      final style = context.text
          .fluid(AppCheckoutSizes.terminalFont)
          .copyWith(color: color);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            height: sm.terminalHeight,
            padding: EdgeInsets.all(
              small
                  ? AppCheckoutSizes.terminalPadSmall
                  : AppCheckoutSizes.terminalPad,
            ),
            decoration: BoxDecoration(
              color: c.secondary,
              borderRadius: BorderRadius.circular(AppRadii.r10),
              border: Border.all(color: c.border, width: AppSizes.borderWidth),
            ),
            // The prototype's wrapped flex row overflows visibly; here the
            // content is clipped to the box instead.
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        AppIcons.creditCard,
                        size: AppCheckoutSizes.terminalIcon,
                        color: color,
                      ),
                      const SizedBox(width: AppCheckoutSizes.terminalGap),
                      Expanded(
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: style,
                        ),
                      ),
                      if (active && state == TerminalState.waiting)
                        const AppSpinner(
                          size: AppCheckoutSizes.spinnerSize,
                          strokeWidth: AppCheckoutSizes.spinnerStroke,
                        ),
                    ],
                  ),
                  Text(
                    MoneyFormatter.format(cart.totals.value.total),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: context.text
                        .fluid(
                          AppCheckoutSizes.terminalAmountFont,
                          weight: AppFontWeight.bold,
                        )
                        .copyWith(color: color),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: sm.inlineGap),
          SizedBox(
            height: sm.declineHeight,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          s.simulateDecline(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text
                              .fluid(AppCheckoutSizes.inlineLabelFont)
                              .copyWith(color: c.text),
                        ),
                      ),
                      SizedBox(
                        width: AppCheckoutSizes.declineCheckbox,
                        height: AppCheckoutSizes.declineCheckbox,
                        child: Checkbox(
                          value: pay.decline.value,
                          activeColor: c.blue,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: (v) => pay.setDecline(v ?? false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppCheckoutSizes.cardOptionsGap),
                _RetryButton(
                  label: s.terminalRetry(),
                  onTap: !active || state == TerminalState.waiting
                      ? null
                      : pay.retry,
                ),
              ],
            ),
          ),
          SizedBox(height: sm.inlineGap),
          CompleteButton(
            label: s.completePayment(),
            height: sm.completeHeight,
            fontSize: sm.completeFont,
            onTap: pay.canCompleteCard ? pay.completeCard : null,
          ),
        ],
      );
    });
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final body = AppPressable(
      onTap: onTap,
      borderRadius: AppRadii.r8,
      semanticLabel: label,
      builder: (context, hovered) => Container(
        height: AppCheckoutSizes.retryHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppCheckoutSizes.retryPadX,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.secondary,
          borderRadius: BorderRadius.circular(AppRadii.r8),
          border: Border.all(color: c.border, width: AppSizes.borderWidth),
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: context.text
              .fluid(AppCheckoutSizes.retryFont, weight: AppFontWeight.medium)
              .copyWith(color: c.text),
        ),
      ),
    );
    return onTap == null
        ? Opacity(opacity: AppCheckoutSizes.disabledOpacity, child: body)
        : body;
  }
}
