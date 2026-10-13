import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_density_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/action_button.dart';
import '../controllers/products_panel_controller.dart';
import 'products_shortcut_label.dart';

/// The desktop cart table while the cart has no lines: what to do next and a
/// button that opens the Products panel.
class CartEmptyState extends StatelessWidget {
  const CartEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final shortcut = productsShortcutLabel(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(AppIcons.shoppingCart, size: AppSpacing.s32, color: c.muted),
          const SizedBox(height: AppSpacing.s8),
          Text(
            s.cartEmptyTitle(),
            style: context.text
                .of(
                  AppFontSize.s16,
                  weight: AppFontWeight.semiBold,
                  height: AppLineHeight.base,
                )
                .copyWith(color: c.text),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            s.cartEmptyHint(shortcut),
            textAlign: TextAlign.center,
            style: context.text
                .of(AppFontSize.s13, height: AppLineHeight.base)
                .copyWith(color: c.muted),
          ),
          const SizedBox(height: AppSpacing.s12),
          ActionButton(
            label: s.cartEmptyOpenProducts(),
            icon: AppIcons.layoutGrid,
            tone: ActionTone.blue,
            fit: true,
            height: AppDensitySizes.footerButtonHeight,
            iconSize: AppDensitySizes.footerIcon,
            fontSize: AppFontSize.s13.px,
            onTap: Get.find<ProductsPanelController>().open,
          ),
        ],
      ),
    );
  }
}
