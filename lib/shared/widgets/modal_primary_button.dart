import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_checkout_sizes.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_sizes.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import 'app_pressable.dart';

/// A `.primary` button stretched to the modal width (a flex column item), its
/// content centred, with an optional leading icon; [marginTop] is the CSS
/// margin (12 for `.primary.full`).
class ModalPrimaryButton extends StatelessWidget {
  const ModalPrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.marginTop = 0,
    this.iconSize = AppCheckoutSizes.primaryPlusIcon,
    this.focusNode,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final double marginTop;
  final double iconSize;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(top: marginTop),
      child: AppPressable(
        borderRadius: AppRadii.r8,
        semanticLabel: label,
        focusNode: focusNode,
        onTap: onTap,
        builder: (context, hovered) => Container(
          constraints: const BoxConstraints(
            minHeight: AppSizes.controlMinHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s18,
            vertical: AppSpacing.s12,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.primary,
            borderRadius: BorderRadius.circular(AppRadii.r8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: iconSize, color: c.white),
                const SizedBox(width: AppCheckoutSizes.primaryIconGap),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: context.text
                      .of(
                        AppFontSize.s14,
                        weight: AppFontWeight.medium,
                        height: AppLineHeight.base,
                      )
                      .copyWith(color: c.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
