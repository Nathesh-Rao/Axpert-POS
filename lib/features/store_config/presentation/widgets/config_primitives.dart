import 'package:flutter/material.dart';

import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../shared/widgets/app_input_box.dart';
import '../../../../shared/widgets/app_pressable.dart';

/// A bordered section of the page with a title.
class ConfigCard extends StatelessWidget {
  const ConfigCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadii.r10),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: context.text
                      .of(AppFontSize.s16, weight: AppFontWeight.bold)
                      .copyWith(color: c.text),
                ),
              ),
              ?trailing,
            ],
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s4),
              child: Text(
                subtitle!,
                style: context.text
                    .of(AppFontSize.s12, height: AppLineHeight.base)
                    .copyWith(color: c.muted),
              ),
            ),
          const SizedBox(height: AppSpacing.s12),
          child,
        ],
      ),
    );
  }
}

/// A muted label over its field (4 px apart).
class ConfigLabeled extends StatelessWidget {
  const ConfigLabeled({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          label,
          style: context.text
              .of(AppFontSize.s13, height: AppLineHeight.base)
              .copyWith(color: context.colors.muted),
        ),
        const SizedBox(height: AppSpacing.s4),
        child,
      ],
    );
  }
}

/// The text value style of the page's fields.
TextStyle configValueStyle(BuildContext context) => context.text
    .of(AppFontSize.s14, height: AppLineHeight.base)
    .copyWith(color: context.colors.text);

/// The muted note style.
TextStyle configNoteStyle(BuildContext context) => context.text
    .of(AppFontSize.s12, height: AppLineHeight.base)
    .copyWith(color: context.colors.muted);

/// A text field of the page; read only when [editable] is false.
class ConfigInput extends StatelessWidget {
  const ConfigInput({
    required this.controller,
    required this.editable,
    required this.semanticLabel,
    this.onChanged,
    this.onSubmitted,
    this.decimal = false,
    this.hint,
    super.key,
  });

  final TextEditingController controller;
  final bool editable;
  final String semanticLabel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool decimal;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return AppInputBox(
      controller: controller,
      style: configValueStyle(context),
      height: AppSizes.modalInputHeight,
      radius: AppRadii.r8,
      padding: const EdgeInsets.symmetric(
        horizontal: AppCheckoutSizes.formInputPadX,
        vertical: AppCheckoutSizes.formInputPadY,
      ),
      hint: hint,
      decimal: decimal,
      readOnly: !editable,
      enabled: true,
      opacity: editable ? 1 : AppCheckoutSizes.disabledOpacity,
      semanticLabel: semanticLabel,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}

/// A picker that is dimmed and ignores input when [editable] is false.
class ConfigDisabled extends StatelessWidget {
  const ConfigDisabled({
    required this.editable,
    required this.child,
    super.key,
  });

  final bool editable;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (editable) return child;
    return IgnorePointer(
      child: Opacity(opacity: AppCheckoutSizes.disabledOpacity, child: child),
    );
  }
}

/// A text button of the page (secondary look, 43 px high for touch).
class ConfigButton extends StatelessWidget {
  const ConfigButton({
    required this.label,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : AppCheckoutSizes.disabledOpacity,
      child: AppPressable(
        borderRadius: AppRadii.r8,
        onTap: onTap,
        semanticLabel: label,
        builder: (context, hovered) => Container(
          constraints: const BoxConstraints(
            minHeight: AppSizes.controlMinHeight,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s14,
            vertical: AppSpacing.s8,
          ),
          decoration: BoxDecoration(
            color: hovered && enabled ? c.quickAmountHover : c.secondary,
            borderRadius: BorderRadius.circular(AppRadii.r8),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: AppSizes.configIcon, color: c.text),
                const SizedBox(width: AppSpacing.s6),
              ],
              Text(
                label,
                style: context.text
                    .of(AppFontSize.s14, weight: AppFontWeight.medium)
                    .copyWith(color: c.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A square icon button (remove) with a 43 px touch target.
class ConfigIconButton extends StatelessWidget {
  const ConfigIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : AppCheckoutSizes.disabledOpacity,
      child: AppPressable(
        borderRadius: AppRadii.r8,
        onTap: onTap,
        tooltip: tooltip,
        semanticLabel: tooltip,
        builder: (context, hovered) => Container(
          width: AppSizes.controlMinHeight,
          height: AppSizes.controlMinHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hovered && enabled ? c.trashHoverBg : c.trashBg,
            borderRadius: BorderRadius.circular(AppRadii.r8),
          ),
          child: Icon(icon, size: AppSizes.configIcon, color: c.trashFg),
        ),
      ),
    );
  }
}

/// A labelled checkbox row item.
class ConfigCheck extends StatelessWidget {
  const ConfigCheck({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Checkbox(
          value: value,
          onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
          activeColor: c.blue,
          checkColor: c.white,
          side: BorderSide(color: c.radioBorder),
          materialTapTargetSize: MaterialTapTargetSize.padded,
          visualDensity: VisualDensity.compact,
        ),
        Text(label, style: configNoteStyle(context)),
      ],
    );
  }
}
