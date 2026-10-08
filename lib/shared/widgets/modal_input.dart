import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_checkout_sizes.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_sizes.dart';
import '../../core/theme/tokens/app_typography.dart';
import 'app_input_box.dart';
import 'request_focus_on_show.dart';

/// `.modal-input` on its own: 46 px high, secondary fill, radius 8, padding
/// 10 / 13, 9 px above and 20 px below. [autofocus] is the prototype's
/// `autoFocus`.
class ModalInput extends StatelessWidget {
  const ModalInput({
    required this.controller,
    required this.focusNode,
    this.hint,
    this.semanticLabel,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.onKey,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hint;
  final String? semanticLabel;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final KeyEventResult Function(FocusNode, KeyEvent)? onKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final box = Padding(
      padding: const EdgeInsets.only(
        top: AppCheckoutSizes.modalInputMarginTop,
        bottom: AppCheckoutSizes.modalInputMarginBottom,
      ),
      child: AppInputBox(
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
        semanticLabel: semanticLabel,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onKey: onKey,
      ),
    );
    return autofocus
        ? RequestFocusOnShow(focusNode: focusNode, child: box)
        : box;
  }
}
