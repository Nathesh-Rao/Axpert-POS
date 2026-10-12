import 'package:flutter/material.dart';

import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_entry_tokens.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/app_pressable.dart';

/// `Remember me` check box (design placeholder: the choice is not used).
class LoginCheckbox extends StatelessWidget {
  const LoginCheckbox({
    required this.label,
    required this.checked,
    required this.scale,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool checked;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final box = AppEntrySizes.checkbox * scale;
    return AppPressable(
      onTap: onTap,
      borderRadius: AppEntrySizes.checkboxRadius,
      semanticLabel: label,
      builder: (context, hovered) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppEntrySizes.minTouch),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: AppEntryMotion.controlMs),
              width: box,
              height: box,
              decoration: BoxDecoration(
                color: checked ? c.blue : context.entryColors.fieldFill,
                borderRadius: BorderRadius.circular(
                  AppEntrySizes.checkboxRadius * scale,
                ),
                border: Border.all(
                  color: checked
                      ? c.blue
                      : hovered
                      ? context.entryColors.fieldHoverBorder
                      : c.border,
                  width: AppSizes.borderWidth,
                ),
              ),
              child: checked
                  ? Icon(AppIcons.check, size: box * 0.75, color: c.white)
                  : null,
            ),
            SizedBox(width: AppEntrySizes.checkboxGap * scale),
            Text(
              label,
              style: context.text
                  .fluid(AppEntrySizes.labelFont * scale)
                  .copyWith(color: c.text),
            ),
          ],
        ),
      ),
    );
  }
}

/// `or` between two thin lines.
class LoginDivider extends StatelessWidget {
  const LoginDivider({required this.label, required this.scale, super.key});

  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final line = Expanded(
      child: Container(height: AppSizes.borderWidth, color: c.border),
    );
    return Row(
      children: <Widget>[
        line,
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppEntrySizes.fieldPadding * scale,
          ),
          child: Text(
            label,
            style: context.text
                .fluid(AppEntrySizes.smallFont * scale)
                .copyWith(color: c.muted),
          ),
        ),
        line,
      ],
    );
  }
}

/// `English` language chip at the top right (design placeholder).
class LanguageChip extends StatelessWidget {
  const LanguageChip({
    required this.label,
    required this.scale,
    required this.onTap,
    super.key,
  });

  final String label;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final entry = context.entryColors;
    final radius = AppEntrySizes.chipRadius * scale;
    return AppPressable(
      onTap: onTap,
      borderRadius: radius,
      semanticLabel: label,
      builder: (context, hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: AppEntryMotion.controlMs),
        width: AppEntrySizes.chipWidth * scale,
        height: (AppEntrySizes.chipHeight * scale).clamp(
          AppEntrySizes.minTouch,
          double.infinity,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppEntrySizes.fieldPadding * scale,
        ),
        decoration: BoxDecoration(
          color: entry.fieldFill,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: hovered ? entry.fieldHoverBorder : c.border,
            width: AppSizes.borderWidth,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              AppIcons.globe,
              size: AppEntrySizes.fieldIcon * scale,
              color: c.text,
            ),
            SizedBox(width: AppEntrySizes.fieldIconGap * scale),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                style: context.text
                    .fluid(
                      AppEntrySizes.labelFont * scale,
                      weight: AppFontWeight.medium,
                    )
                    .copyWith(color: c.text),
              ),
            ),
            Icon(
              AppIcons.chevronDown,
              size: AppEntrySizes.fieldIcon * scale,
              color: c.text,
            ),
          ],
        ),
      ),
    );
  }
}
