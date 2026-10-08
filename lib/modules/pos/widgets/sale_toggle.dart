import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../controllers/cart_controller.dart';
import '../controllers/cart_meta_controller.dart';
import '../models/cart.dart';
import '../../../shared/widgets/app_pressable.dart';

/// `.sale-toggle`: two pills, Cash Sale and Credit Sale, with a radio dot.
class SaleToggle extends StatelessWidget {
  const SaleToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final cart = Get.find<CartController>();
    final meta = Get.find<CartMetaController>();
    return Obx(() {
      final type = cart.cart.value.saleType;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _Pill(
            label: s.saleCash(),
            chosen: type == SaleType.cash,
            cash: true,
            onTap: () => meta.setSaleType(SaleType.cash),
          ),
          const SizedBox(width: AppSpacing.s4),
          _Pill(
            label: s.saleCredit(),
            chosen: type == SaleType.credit,
            cash: false,
            onTap: () => meta.setSaleType(SaleType.credit),
          ),
        ],
      );
    });
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.chosen,
    required this.cash,
    required this.onTap,
  });

  final String label;
  final bool chosen;
  final bool cash;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    final (bg, fg) = chosen
        ? (cash
              ? (c.cashChosenBg, c.cashChosenFg)
              : (c.creditChosenBg, c.creditChosenFg))
        : (c.secondary, c.saleToggleIdleFg);
    final padX = m.atMost1100 ? AppSpacing.s6 : m.saleTogglePadX;
    final padY = m.atMost1100 ? AppSpacing.s6 : m.saleTogglePadY;
    return AppPressable(
      onTap: onTap,
      borderRadius: AppRadii.r22,
      semanticLabel: label,
      builder: (context, hovered) => Container(
        padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.r22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: AppCheckoutSizes.radioSize,
              height: AppCheckoutSizes.radioSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: chosen ? fg : c.radioBorder,
                  width: chosen
                      ? AppCheckoutSizes.radioBorderChosen
                      : AppCheckoutSizes.radioBorder,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s4),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: context.text.fluid(m.catalogFont).copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
