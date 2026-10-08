import 'package:flutter/material.dart';

import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../shared/widgets/app_pressable.dart';

/// `.complete-payment`: full-width green button; the disabled look is its own
/// pale green (not an opacity).
class CompleteButton extends StatelessWidget {
  const CompleteButton({
    required this.label,
    required this.height,
    required this.fontSize,
    required this.onTap,
    super.key,
  });

  final String label;
  final double height;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    return AppPressable(
      onTap: onTap,
      borderRadius: AppRadii.r10,
      semanticLabel: label,
      builder: (context, hovered) => Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? c.primaryGreen : c.completeDisabledBg,
          borderRadius: BorderRadius.circular(AppRadii.r10),
          border: enabled
              ? null
              : Border.all(
                  color: c.completeDisabledBorder,
                  width: AppSizes.borderWidth,
                ),
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: context.text
              .fluid(fontSize, weight: AppFontWeight.semiBold)
              .copyWith(color: enabled ? c.white : c.completeDisabledFg),
        ),
      ),
    );
  }
}
