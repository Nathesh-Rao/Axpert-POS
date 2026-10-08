import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/decimal_text.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/app_modal.dart';
import '../../../../shared/widgets/modal_input.dart';
import '../../controllers/price_check_controller.dart';

/// Price Check (`modal === "priceCheck"`): a lookup, nothing is added.
class PriceCheckDialog extends StatelessWidget {
  const PriceCheckDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final check = Get.find<PriceCheckController>();
    return AppModal(
      title: s.actionPriceCheck(),
      children: <Widget>[
        ModalParagraph(s.priceCheckBody()),
        ModalInput(
          controller: check.text,
          focusNode: check.focus,
          autofocus: true,
          hint: s.priceCheckHint(),
          semanticLabel: s.actionPriceCheck(),
          onChanged: check.onChanged,
          onSubmitted: (_) => check.onSubmit(),
        ),
        Obx(() {
          final product = check.product.value;
          if (product != null) {
            return Container(
              margin: const EdgeInsets.only(
                top: AppCheckoutSizes.priceResultMarginTop,
              ),
              padding: const EdgeInsets.all(AppCheckoutSizes.priceResultPad),
              decoration: BoxDecoration(
                color: c.secondary,
                borderRadius: BorderRadius.circular(AppRadii.r10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    product.name,
                    style: context.text
                        .fluid(
                          AppCheckoutSizes.priceResultNameFont,
                          weight: AppFontWeight.bold,
                          height: AppLineHeight.base,
                        )
                        .copyWith(color: c.text),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppCheckoutSizes.priceResultPriceMarginY,
                    ),
                    child: Text(
                      MoneyFormatter.format(product.price),
                      maxLines: 1,
                      softWrap: false,
                      style: context.text
                          .of(AppFontSize.s36, weight: AppFontWeight.bold)
                          .copyWith(color: c.blue),
                    ),
                  ),
                  Text(
                    s.priceCheckDetails(
                      product.code,
                      product.stock,
                      DecimalText.scaled(product.gst.value, 2),
                    ),
                    style: context.text
                        .of(AppFontSize.s14, height: AppLineHeight.base)
                        .copyWith(color: c.muted),
                  ),
                ],
              ),
            );
          }
          if (check.query.value.isNotEmpty) {
            return ModalParagraph(s.priceCheckNoMatch());
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }
}
