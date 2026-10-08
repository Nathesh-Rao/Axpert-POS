import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/responsive/app_metrics_scope.dart';
import '../../../../core/responsive/summary_metrics.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/decimal_text.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/forex_controller.dart';
import 'summary_card.dart';

/// The conversion card: FC and selected-currency amounts plus the exchange
/// rate. Ported as-is: both boxes show the same converted amount and the
/// selector only changes its label (KG-107).
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
                    s.forexFc(),
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
                          items: ForexController.currencies,
                          labelOf: s.forexCurrencyLabel,
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
              height: sm.rateLabelHeight + AppCheckoutSizes.rateMarginTop,
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

class _RateRow extends StatefulWidget {
  const _RateRow();

  @override
  State<_RateRow> createState() => _RateRowState();
}

class _RateRowState extends State<_RateRow> {
  final ForexController _forex = Get.find<ForexController>();
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'rate');
  Worker? _worker;

  @override
  void initState() {
    super.initState();
    _text.text = DecimalText.scaled(_forex.rateMilli, 3);
    // Follow the stored rate unless the user is typing in the field.
    _worker = ever<int>(Get.find<ForexController>().settingsRate, (_) {
      if (!_focus.hasFocus) {
        _text.text = DecimalText.scaled(_forex.rateMilli, 3);
      }
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final style = context.text
        .fluid(AppCheckoutSizes.rateFont)
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
            child: TextField(
              controller: _text,
              focusNode: _focus,
              textAlign: TextAlign.right,
              textAlignVertical: TextAlignVertical.center,
              expands: true,
              maxLines: null,
              minLines: null,
              style: style.copyWith(color: c.text),
              cursorColor: c.blue,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                semanticCounterText: s.forexRateSemantic(),
              ),
              onChanged: _forex.commitRate,
              onTapOutside: (_) => _focus.unfocus(),
            ),
          ),
        ),
      ],
    );
  }
}
