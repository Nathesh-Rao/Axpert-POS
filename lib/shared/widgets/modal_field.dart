import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_checkout_sizes.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_sizes.dart';
import '../../core/theme/tokens/app_typography.dart';
import 'app_input_box.dart';

/// `label.form-label` with a `.modal-input`: muted 13 px label 15 px below the
/// previous block, the 46 px input 9 px under it and 10 px of space after.
class ModalField extends StatelessWidget {
  const ModalField({
    required this.label,
    required this.controller,
    this.focusNode,
    this.hint,
    this.decimal = false,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hint;
  final bool decimal;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(
        top: AppCheckoutSizes.formLabelMarginTop,
        bottom: AppCheckoutSizes.formInputMarginBottom,
      ),
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
          AppInputBox(
            controller: controller,
            focusNode: focusNode,
            style: context.text
                .of(AppFontSize.s14, height: AppLineHeight.base)
                .copyWith(color: c.text),
            height: AppSizes.modalInputHeight,
            radius: AppRadii.r8,
            padding: const EdgeInsets.symmetric(
              horizontal: AppCheckoutSizes.formInputPadX,
              vertical: AppCheckoutSizes.formInputPadY,
            ),
            hint: hint,
            decimal: decimal,
            semanticLabel: label,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
          ),
        ],
      ),
    );
  }
}
