import 'package:flutter/material.dart';

import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_entry_tokens.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/app_pressable.dart';

double _touchHeight(double base, double scale) =>
    (base * scale).clamp(AppEntrySizes.minTouch, double.infinity);

/// Filled blue button (`Sign In`), with a loading state.
class LoginPrimaryButton extends StatelessWidget {
  const LoginPrimaryButton({
    required this.label,
    required this.icon,
    required this.scale,
    required this.loading,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final double scale;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final radius = AppEntrySizes.fieldRadius * scale;
    final style = context.text
        .fluid(AppEntrySizes.buttonFont * scale, weight: AppFontWeight.medium)
        .copyWith(color: c.white);
    return AppPressable(
      onTap: loading ? null : onTap,
      borderRadius: radius,
      semanticLabel: label,
      builder: (context, hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: AppEntryMotion.controlMs),
        height: _touchHeight(AppEntrySizes.buttonHeight, scale),
        decoration: BoxDecoration(
          color: loading || hovered ? c.primary : c.blue,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (loading) ...<Widget>[
                SizedBox(
                  width: AppEntrySizes.spinner * scale,
                  height: AppEntrySizes.spinner * scale,
                  child: CircularProgressIndicator(
                    color: c.white,
                    strokeWidth: AppEntrySizes.spinnerStroke * scale,
                  ),
                ),
                SizedBox(width: AppEntrySizes.buttonIconGap * scale),
                Text(label, style: style),
              ] else ...<Widget>[
                Text(label, style: style),
                SizedBox(width: AppEntrySizes.buttonIconGap * scale),
                Icon(
                  icon,
                  size: AppEntrySizes.fieldIcon * scale,
                  color: c.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// White button with a border (`Login with QR Code`).
class LoginOutlineButton extends StatelessWidget {
  const LoginOutlineButton({
    required this.label,
    required this.icon,
    required this.scale,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final entry = context.entryColors;
    final radius = AppEntrySizes.fieldRadius * scale;
    final style = context.text
        .fluid(AppEntrySizes.labelFont * scale, weight: AppFontWeight.medium)
        .copyWith(color: c.text);
    return AppPressable(
      onTap: onTap,
      borderRadius: radius,
      semanticLabel: label,
      builder: (context, hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: AppEntryMotion.controlMs),
        height: _touchHeight(AppEntrySizes.fieldHeight, scale),
        decoration: BoxDecoration(
          color: entry.fieldFill,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: hovered ? entry.fieldHoverBorder : c.border,
            width: AppSizes.borderWidth,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: AppEntrySizes.fieldIcon * scale, color: c.text),
              SizedBox(width: AppEntrySizes.fieldIconGap * scale),
              Text(label, style: style),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blue text link (`Forgot Password?`).
class LoginLink extends StatelessWidget {
  const LoginLink({
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
    return AppPressable(
      onTap: onTap,
      borderRadius: AppEntrySizes.checkboxRadius,
      semanticLabel: label,
      builder: (context, hovered) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppEntrySizes.minTouch),
        child: Center(
          child: Text(
            label,
            style: context.text
                .fluid(
                  AppEntrySizes.labelFont * scale,
                  weight: AppFontWeight.medium,
                )
                .copyWith(
                  color: c.blue,
                  decoration: hovered ? TextDecoration.underline : null,
                  decorationColor: c.blue,
                ),
          ),
        ),
      ),
    );
  }
}
