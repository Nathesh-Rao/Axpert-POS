import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/responsive/app_metrics_scope.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../controllers/cart_controller.dart';
import 'summary_card.dart';

/// Subtotal, Discount, Reward Points, Tax Amount and the Invoice Total.
class TotalsCard extends StatelessWidget {
  const TotalsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final sm = m.summary;
    final s = context.strings;
    final c = context.colors;
    final cart = Get.find<CartController>();
    return SummaryCard(
      padding: sm.cardPad,
      child: Obx(() {
        final t = cart.totals.value;
        Widget row(String label, String value) => SizedBox(
          height: sm.rowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text
                        .fluid(sm.rowFont)
                        .copyWith(color: c.summaryRowText),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  style: context.text
                      .fluid(sm.rowValueFont, weight: AppFontWeight.bold)
                      .copyWith(color: c.text),
                ),
              ],
            ),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            row(s.summarySubtotal(), MoneyFormatter.format(t.subtotal)),
            row(s.summaryDiscount(), MoneyFormatter.format(t.discount)),
            row(s.summaryRewardPoints(), MoneyFormatter.format(t.points)),
            row(s.summaryTaxAmount(), MoneyFormatter.format(t.tax)),
            const SizedBox(height: AppCheckoutSizes.invoiceMarginTop),
            Container(
              height: sm.invoiceHeight,
              padding: EdgeInsets.all(sm.invoicePad),
              decoration: BoxDecoration(
                color: c.invoiceBg,
                borderRadius: BorderRadius.circular(AppRadii.r10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    s.summaryInvoiceTotal(),
                    maxLines: 1,
                    softWrap: false,
                    style: context.text
                        .fluid(sm.invoiceLabelFont, weight: AppFontWeight.bold)
                        .copyWith(color: c.invoiceFg),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        MoneyFormatter.format(t.total),
                        maxLines: 1,
                        softWrap: false,
                        style: context.text
                            .fluid(
                              sm.invoiceTotalFont,
                              weight: AppFontWeight.bold,
                              letterSpacing: AppTracking.invoiceTotal,
                            )
                            .copyWith(color: c.invoiceFg),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
