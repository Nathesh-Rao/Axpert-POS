import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../../../shared/widgets/css_gradient.dart';
import '../controllers/cart_controller.dart';
import '../controllers/cart_meta_controller.dart';
import '../models/cart.dart';
import 'customer_select.dart';

/// "Customer" label, the field (icon, select, search button) with the Add
/// Customer button, then the credit validation and the order note.
class CustomerRow extends StatelessWidget {
  const CustomerRow({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final s = context.strings;
    final c = context.colors;
    final overlay = Get.find<OverlayController>();
    final cart = Get.find<CartController>();
    final meta = Get.find<CartMetaController>();
    final small = m.atMost1100;
    final fontStyle = context.text.fluid(m.catalogFont);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(
            top: m.customerLabelMarginTop,
            bottom: AppCheckoutSizes.customerLabelMarginBottom,
          ),
          child: Text(
            s.customerLabel(),
            style: context.text
                .fluid(AppCheckoutSizes.customerLabelFont)
                .copyWith(color: c.labelText),
          ),
        ),
        SizedBox(
          height: m.fieldHeight,
          child: Row(
            children: <Widget>[
              Expanded(
                child: CssGradientBox(
                  angleDeg: 120,
                  colors: <Color>[c.secondary, c.card],
                  borderRadius: BorderRadius.circular(AppRadii.r7),
                  border: Border.all(color: c.border),
                  padding: EdgeInsets.symmetric(
                    horizontal: m.fieldPadX + AppSizes.borderWidth,
                    vertical: AppSizes.borderWidth,
                  ),
                  child: Row(
                    children: <Widget>[
                      if (!small) ...<Widget>[
                        Icon(
                          AppIcons.userRound,
                          size: m.atMost1280
                              ? AppSizes.fieldClearIcon
                              : AppCheckoutSizes.customerRowIcon,
                          color: c.fieldIcon,
                        ),
                        SizedBox(width: m.fieldGap),
                      ],
                      Expanded(
                        child: CustomerSelect(
                          style: fontStyle,
                          semanticLabel: s.customerLabel(),
                        ),
                      ),
                      SizedBox(width: m.fieldGap),
                      AppPressable(
                        tooltip: s.customerFindTooltip(),
                        borderRadius: AppRadii.r6,
                        onTap: () => overlay.open('customers'),
                        builder: (context, hovered) => Container(
                          padding: EdgeInsets.only(left: m.fieldGap),
                          decoration: BoxDecoration(
                            border: Border(left: BorderSide(color: c.border)),
                          ),
                          child: Icon(
                            AppIcons.search,
                            size: AppCheckoutSizes.customerFindIcon,
                            color: c.fieldIcon,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s6),
              AppPressable(
                borderRadius: AppRadii.r7,
                semanticLabel: s.addCustomerButton(),
                onTap: () => overlay.open('addCustomer'),
                builder: (context, hovered) => Container(
                  height: m.fieldHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: small
                        ? AppSpacing.s6
                        : AppCheckoutSizes.addCustomerPadX,
                  ),
                  decoration: BoxDecoration(
                    color: c.actionBlueBg,
                    borderRadius: BorderRadius.circular(AppRadii.r7),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        AppIcons.plus,
                        size: small
                            ? AppCheckoutSizes.addCustomerIconSmall
                            : AppCheckoutSizes.addCustomerIcon,
                        color: c.blue,
                      ),
                      const SizedBox(width: AppSpacing.s5),
                      Text(
                        s.addCustomerButton(),
                        maxLines: 1,
                        softWrap: false,
                        style: context.text
                            .fluid(
                              small
                                  ? AppCheckoutSizes.addCustomerFontSmall
                                  : AppCheckoutSizes.addCustomerFont,
                            )
                            .copyWith(color: c.blue),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Obx(() {
          final value = cart.cart.value;
          final credit =
              value.saleType == SaleType.credit && meta.customer.isWalkIn;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (credit)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppCheckoutSizes.validationMarginTop,
                  ),
                  child: Text(
                    s.creditValidation(),
                    style: context.text
                        .fluid(AppCheckoutSizes.validationFont)
                        .copyWith(color: c.validation),
                  ),
                ),
              if (value.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppCheckoutSizes.noteMarginTop,
                  ),
                  child: Text(
                    s.orderNote(value.note),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.text
                        .fluid(AppCheckoutSizes.noteFont)
                        .copyWith(color: c.muted),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}
