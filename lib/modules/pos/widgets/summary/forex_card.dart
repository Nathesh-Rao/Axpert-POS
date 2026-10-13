import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/responsive/app_metrics_scope.dart';
import '../../../../core/responsive/summary_metrics.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/forex_controller.dart';
import 'summary_card.dart';

/// The conversion card: the selected foreign currency and its amount plus the
/// exchange rate, all from the store's forex rows. Both boxes show the same
/// converted amount (KG-107).
class ForexCard extends StatelessWidget {
  const ForexCard({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final sm = m.summary;
    final s = context.strings;
    final c = context.colors;
    final forex = Get.find<ForexController>();
    final cart = Get.find<CartController>();
    final style = context.text.fluid(sm.currencyRowFont);
    final padY = sm.density == SummaryDensity.normal
        ? AppCheckoutSizes.currencyPad
        : AppCheckoutSizes.currencyPadSmall;
    Widget box(Widget leading, String value) => Expanded(
      child: Container(
        height: sm.currencyRowHeight,
        padding: EdgeInsets.symmetric(
          horizontal: AppCheckoutSizes.currencyPad,
          vertical: padY,
        ),
        decoration: BoxDecoration(
          color: c.secondary,
          borderRadius: BorderRadius.circular(AppRadii.r8),
        ),
        child: Row(
          children: <Widget>[
            leading,
            const SizedBox(width: AppCheckoutSizes.currencyInnerGap),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(color: c.text),
              ),
            ),
          ],
        ),
      ),
    );
    return SummaryCard(
      padding: sm.cardPad,
      child: Obx(() {
        final converted = forex.converted(cart.totals.value.total);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                box(
                  Text(
                    forex.currency.value,
                    style: style
                        .copyWith(fontWeight: AppFontWeight.bold.value)
                        .copyWith(color: c.text),
                  ),
                  converted,
                ),
                const SizedBox(width: AppCheckoutSizes.currencyGap),
                box(
                  Flexible(
                    flex: 0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppCheckoutSizes.currencySelectMaxWidth,
                      ),
                      child: IntrinsicWidth(
                        child: AppDropdown<String>(
                          value: forex.currency.value,
                          items: forex.codes,
                          labelOf: (code) => code,
                          onChanged: forex.setCurrency,
                          style: style,
                          semanticLabel: s.forexCurrencySemantic(),
                        ),
                      ),
                    ),
                  ),
                  converted,
                ),
              ],
            ),
            SizedBox(
              height: sm.rateRowHeight + AppCheckoutSizes.rateMarginTop,
              child: const Padding(
                padding: EdgeInsets.only(top: AppCheckoutSizes.rateMarginTop),
                child: _RateRow(),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// The exchange rate of the selected row (read only: the rate is store data).
class _RateRow extends StatelessWidget {
  const _RateRow();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final forex = Get.find<ForexController>();
    final style = context.text
        .fluid(
          context.metrics.summary.rateFont,
          height: SummaryMetrics.inputLineHeight,
        )
        .copyWith(color: c.muted);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Text(s.forexRateLabel(), maxLines: 1, softWrap: false, style: style),
        const SizedBox(width: AppCheckoutSizes.rateGap),
        SizedBox(
          width: AppCheckoutSizes.rateInputWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Semantics(
              label: s.forexRateSemantic(),
              child: Align(
                alignment: Alignment.centerRight,
                child: Obx(
                  () => Text(
                    forex.rateText,
                    maxLines: 1,
                    softWrap: false,
                    style: style.copyWith(color: c.text),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
