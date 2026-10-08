import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/responsive/app_metrics_scope.dart';
import '../../../../core/responsive/summary_metrics.dart';
import '../../../../core/services/pricing/money.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/app_input_box.dart';
import '../../../../shared/widgets/app_pressable.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/payment_controller.dart';
import 'complete_button.dart';

/// Cash inline payment: amount due, tendered field, quick amounts, change due
/// and the Complete button (a credit sale disables everything but Save).
class CashPanel extends StatelessWidget {
  const CashPanel({super.key});

  static const List<int> quickWholeAmounts = <int>[100, 500, 2000];

  @override
  Widget build(BuildContext context) {
    final sm = context.metrics.summary;
    final s = context.strings;
    final c = context.colors;
    final pay = Get.find<PaymentController>();
    final cart = Get.find<CartController>();
    final label = context.text
        .fluid(AppCheckoutSizes.inlineLabelFont)
        .copyWith(color: c.text);
    final value = context.text
        .fluid(
          AppCheckoutSizes.inlineValueFont,
          weight: AppFontWeight.bold,
          height: AppLineHeight.inlineValue,
        )
        .copyWith(color: c.text);
    return Obx(() {
      // Rebuild on every input that decides the state.
      final totals = cart.totals.value;
      pay.tenderedValue.value; // rebuild on every keystroke
      final canPay = pay.canPay;
      final credit = pay.isCredit;
      final inputsOn = canPay && !credit;
      final change = pay.changeDue;
      final short = pay.isShort;
      final total = totals.total;
      Widget line(String text, String amount, {Color? color}) => SizedBox(
        height: sm.inlineAmountHeight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(text, style: label),
            Flexible(
              child: Text(
                amount,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: color == null ? value : value.copyWith(color: color),
              ),
            ),
          ],
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          line(s.amountDue(), MoneyFormatter.format(total)),
          SizedBox(height: sm.inlineGap),
          SizedBox(
            height: sm.tenderedHeight,
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: AppCheckoutSizes.tenderedLabelFlex,
                  child: Text(
                    s.amountTendered(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: label,
                  ),
                ),
                const SizedBox(width: AppCheckoutSizes.inlineTenderedGap),
                Expanded(
                  flex: AppCheckoutSizes.tenderedInputFlex,
                  child: AppInputBox(
                    controller: pay.tendered,
                    focusNode: pay.tenderedFocus,
                    style: context.text
                        .fluid(
                          sm.tenderedFont,
                          weight: AppFontWeight.semiBold,
                          height: SummaryMetrics.inputLineHeight,
                        )
                        .copyWith(color: c.text),
                    height: sm.tenderedHeight,
                    radius: AppRadii.r8,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.s8,
                      vertical: sm.tenderedPadY,
                    ),
                    hint: s.amountTenderedHint(),
                    enabled: inputsOn,
                    decimal: true,
                    semanticLabel: s.amountTendered(),
                    opacity: inputsOn ? 1 : AppCheckoutSizes.disabledOpacity,
                    onSubmitted: (_) => pay.submitTendered(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: sm.inlineGap),
          Row(
            children: <Widget>[
              for (var i = 0; i < 4; i++) ...<Widget>[
                if (i > 0)
                  const SizedBox(width: AppCheckoutSizes.quickAmountGap),
                Expanded(
                  child: _QuickAmount(
                    label: i == 0
                        ? s.quickAmountExact()
                        : _whole(CashPanel.quickWholeAmounts[i - 1], total),
                    height: sm.quickAmountHeight,
                    fontSize: sm.quickAmountFont,
                    onTap: inputsOn
                        ? () => pay.setQuickAmount(
                            i == 0 ? null : CashPanel.quickWholeAmounts[i - 1],
                          )
                        : null,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: sm.inlineGap),
          line(
            s.changeDue(),
            _signed(change),
            color: short ? c.shortChangeRed : c.changeDueGreen,
          ),
          SizedBox(height: sm.inlineGap),
          CompleteButton(
            label: credit ? s.saveOnCredit() : s.completePayment(),
            height: sm.completeHeight,
            fontSize: sm.completeFont,
            onTap: pay.canCompleteCash ? pay.completeCash : null,
          ),
        ],
      );
    });
  }

  /// `amount.toLocaleString("en-IN")` for a whole currency amount.
  static String _whole(int amount, Money total) {
    var unit = 1;
    for (var i = 0; i < total.currency.exponent; i++) {
      unit *= 10;
    }
    return MoneyFormatter.formatMinor(
      amount * unit,
      total.currency,
      symbol: false,
    ).split('.').first;
  }

  /// `money(x)` of the prototype: symbol first, then the signed number
  /// ("₹-21.00").
  static String _signed(Money m) =>
      '${m.currency.symbol}${MoneyFormatter.formatMinor(m.minor, m.currency, symbol: false)}';
}

class _QuickAmount extends StatelessWidget {
  const _QuickAmount({
    required this.label,
    required this.height,
    required this.fontSize,
    required this.onTap,
  });

  final String label;
  final double height;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final body = AppPressable(
      onTap: onTap,
      borderRadius: AppRadii.r8,
      semanticLabel: label,
      builder: (context, hovered) => Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hovered && onTap != null
              ? c.quickAmountHover
              : c.quickAmountBg,
          borderRadius: BorderRadius.circular(AppRadii.r8),
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: context.text
              .fluid(fontSize, weight: AppFontWeight.medium)
              .copyWith(color: c.blue),
        ),
      ),
    );
    return onTap == null
        ? Opacity(opacity: AppCheckoutSizes.disabledOpacity, child: body)
        : body;
  }
}
