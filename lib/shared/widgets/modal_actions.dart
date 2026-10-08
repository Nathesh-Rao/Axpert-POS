import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_sizes.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import 'app_pressable.dart';

/// `.modal-actions`: a secondary and a primary button, right aligned, 9 px
/// apart, 20 px above and 8 px below. Like the prototype, the primary button
/// carries a 20 px top margin inside the flex row, so the secondary button
/// stretches to the taller row.
class ModalActions extends StatelessWidget {
  const ModalActions({
    required this.secondaryLabel,
    required this.onSecondary,
    required this.primaryLabel,
    required this.onPrimary,
    super.key,
  });

  final String secondaryLabel;
  final VoidCallback onSecondary;
  final String primaryLabel;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = context.text.of(
      AppFontSize.s14,
      weight: AppFontWeight.medium,
      height: AppLineHeight.base,
    );
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.s20,
        bottom: AppSpacing.s8,
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Flexible(
              child: AppPressable(
                borderRadius: AppRadii.r8,
                onTap: onSecondary,
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
                    color: c.secondary,
                    borderRadius: BorderRadius.circular(AppRadii.r8),
                    border: Border.all(color: c.border),
                  ),
                  child: Text(
                    secondaryLabel,
                    textAlign: TextAlign.center,
                    style: label.copyWith(color: c.text),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s9),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s20),
                child: AppPressable(
                  borderRadius: AppRadii.r8,
                  onTap: onPrimary,
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
                    child: Text(
                      primaryLabel,
                      textAlign: TextAlign.center,
                      style: label.copyWith(color: c.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
