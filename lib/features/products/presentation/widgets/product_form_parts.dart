import 'package:flutter/material.dart';

import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../core/theme/tokens/app_icons.dart';
import '../../../../core/theme/tokens/app_product_form_sizes.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../shared/widgets/app_input_box.dart';
import '../../../../shared/widgets/app_pressable.dart';

/// Muted 13 px label above a control, with the error line under it.
class FormBlock extends StatelessWidget {
  const FormBlock({
    required this.label,
    required this.child,
    this.error,
    super.key,
  });

  final String label;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            label,
            style: context.text
                .of(AppFontSize.s13, height: AppLineHeight.base)
                .copyWith(color: c.muted),
          ),
          const SizedBox(height: AppCheckoutSizes.formInputGap),
          child,
          if (error != null && error!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s4),
              child: Text(
                error!,
                style: context.text
                    .of(AppFontSize.s12, height: AppLineHeight.base)
                    .copyWith(color: c.validation),
              ),
            ),
        ],
      ),
    );
  }
}

/// The 46 px text box of the modals, with an error colour on its border.
class FormInput extends StatelessWidget {
  const FormInput({
    required this.controller,
    required this.label,
    this.hint,
    this.decimal = false,
    this.digitsOnly = false,
    this.hasError = false,
    this.onSubmitted,
    this.focusNode,
    this.height = AppSizes.modalInputHeight,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool decimal;
  final bool digitsOnly;
  final bool hasError;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppInputBox(
      controller: controller,
      focusNode: focusNode,
      style: context.text
          .of(AppFontSize.s14, height: AppLineHeight.base)
          .copyWith(color: c.text),
      height: height,
      radius: AppRadii.r8,
      padding: const EdgeInsets.symmetric(
        horizontal: AppCheckoutSizes.formInputPadX,
        vertical: AppCheckoutSizes.formInputPadY,
      ),
      borderColor: hasError ? c.validation : null,
      hint: hint,
      decimal: decimal,
      digitsOnly: digitsOnly,
      semanticLabel: label,
      onSubmitted: onSubmitted,
    );
  }
}

/// Section heading ("Packaging", "Stock").
class FormSectionTitle extends StatelessWidget {
  const FormSectionTitle(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.s12,
        bottom: AppSpacing.s8,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              text,
              style: context.text
                  .of(
                    AppFontSize.s16,
                    weight: AppFontWeight.bold,
                    height: AppLineHeight.base,
                  )
                  .copyWith(color: c.text),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// An on/off box with a label (active, packaging on).
class OnOffToggle extends StatelessWidget {
  const OnOffToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPressable(
      semanticLabel: label,
      borderRadius: AppRadii.r6,
      onTap: () => onChanged(!value),
      builder: (context, hovered) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: AppProductFormSizes.toggleBox,
            height: AppProductFormSizes.toggleBox,
            decoration: BoxDecoration(
              color: value ? c.primary : c.card,
              borderRadius: BorderRadius.circular(AppRadii.r6),
              border: Border.all(
                color: value || hovered ? c.primary : c.border,
                width: AppSizes.borderWidth,
              ),
            ),
            child: value
                ? Icon(
                    AppIcons.check,
                    size: AppProductFormSizes.toggleIcon,
                    color: c.white,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.s8),
          Text(
            label,
            style: context.text
                .of(AppFontSize.s14, height: AppLineHeight.base)
                .copyWith(color: c.text),
          ),
        ],
      ),
    );
  }
}

/// A small text button ("+ New", "Add packaging").
class FormTextButton extends StatelessWidget {
  const FormTextButton({
    required this.label,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPressable(
      semanticLabel: label,
      borderRadius: AppRadii.r6,
      onTap: onTap,
      builder: (context, hovered) => Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.s4,
          horizontal: AppSpacing.s4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: AppSpacing.s16, color: c.primary),
              const SizedBox(width: AppSpacing.s4),
            ],
            Text(
              label,
              style: context.text
                  .of(
                    AppFontSize.s13,
                    weight: AppFontWeight.medium,
                    height: AppLineHeight.base,
                  )
                  .copyWith(
                    color: c.primary,
                    decoration: hovered ? TextDecoration.underline : null,
                    decorationColor: c.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
