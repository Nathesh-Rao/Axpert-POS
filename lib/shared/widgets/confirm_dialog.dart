import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_strings_x.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_sizes.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../controllers/overlay_controller.dart';
import 'app_modal.dart';
import 'app_pressable.dart';

/// "Confirm action" dialog: question, Cancel and Confirm. Like the prototype,
/// the primary button carries a 20 px top margin inside the flex row, so the
/// secondary button stretches to the taller row.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final overlay = Get.find<OverlayController>();
    final label = context.text.of(
      AppFontSize.s14,
      weight: AppFontWeight.medium,
      height: AppLineHeight.base,
    );
    return AppModal(
      title: s.confirmTitle(),
      children: <Widget>[
        Text(
          text,
          style: context.text
              .of(AppFontSize.s14, height: AppLineHeight.modalBody)
              .copyWith(color: c.text),
        ),
        const SizedBox(height: AppSpacing.s20),
        IntrinsicHeight(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppPressable(
                borderRadius: AppRadii.r8,
                onTap: overlay.close,
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
                    s.confirmCancel(),
                    style: label.copyWith(color: c.text),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s9),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s20),
                child: AppPressable(
                  borderRadius: AppRadii.r8,
                  onTap: overlay.accept,
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
                      s.confirmAccept(),
                      style: label.copyWith(color: c.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
      ],
    );
  }
}
