import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_density_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_shadows.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../controllers/products_panel_controller.dart';
import 'products_shortcut_label.dart';

/// The slim tab on the left edge of the desktop POS work area: icon, the word
/// "Products" turned upwards and the shortcut. Click (or Ctrl/Cmd+B) shows or
/// hides the Products panel.
class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final panel = Get.find<ProductsPanelController>();
    final shortcut = productsShortcutLabel(context);
    return Obx(() {
      final open = panel.isOpen;
      return AppPressable(
        onTap: panel.toggle,
        tooltip: s.productsTabSemantic(shortcut),
        semanticLabel: s.productsTabSemantic(shortcut),
        borderRadius: AppRadii.r14,
        builder: (context, hovered) => Container(
          width: AppDensitySizes.productsTabWidth,
          decoration: BoxDecoration(
            color: open
                ? c.selectedTabBg
                : hovered
                ? c.secondary
                : c.card,
            borderRadius: BorderRadius.circular(AppRadii.r14),
            boxShadow: AppShadows.panel.boxShadows,
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
          child: Column(
            children: <Widget>[
              Icon(
                AppIcons.layoutGrid,
                size: AppDensitySizes.productsTabIcon,
                color: c.blue,
              ),
              const SizedBox(height: AppSpacing.s12),
              Expanded(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        s.productsTabLabel(),
                        maxLines: 1,
                        softWrap: false,
                        style: context.text
                            .of(
                              AppFontSize.s13,
                              weight: AppFontWeight.semiBold,
                              height: AppLineHeight.base,
                            )
                            .copyWith(color: c.text),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: c.border),
                          borderRadius: BorderRadius.circular(AppRadii.r6),
                        ),
                        child: Text(
                          shortcut,
                          maxLines: 1,
                          softWrap: false,
                          style: context.text
                              .of(AppFontSize.s11, height: AppLineHeight.base)
                              .copyWith(color: c.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
