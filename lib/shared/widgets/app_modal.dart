import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_strings_x.dart';
import '../../core/responsive/app_metrics_scope.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_checkout_sizes.dart';
import '../../core/theme/tokens/app_icons.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_shadows.dart';
import '../../core/theme/tokens/app_sizes.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import '../controllers/overlay_controller.dart';
import 'app_pressable.dart';

/// `.modal`: 460 wide card, 16 px radius, modal shadow, 25 px bold title.
class AppModal extends StatelessWidget {
  const AppModal({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    return Padding(
      padding: EdgeInsets.all(m.modalOverlayPad),
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.modalWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(AppRadii.r16),
                boxShadow: AppShadows.modal.boxShadows,
              ),
              child: Stack(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(m.modalPad),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[ModalTitle(title), ...children],
                    ),
                  ),
                  const ModalCloseButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `.modal h2`: 25 px bold, 12 px below, 20 px reserved for the close button.
class ModalTitle extends StatelessWidget {
  const ModalTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        right: AppSpacing.s20,
        bottom: AppSpacing.s12,
      ),
      child: Text(
        text,
        style: context.text
            .of(AppFontSize.s25, weight: AppFontWeight.bold)
            .copyWith(color: context.colors.text),
      ),
    );
  }
}

/// `.modal-close`: right 14, top 14, padding 5, round. Place it in a [Stack].
class ModalCloseButton extends StatelessWidget {
  const ModalCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned(
      right: AppSpacing.s14,
      top: AppSpacing.s14,
      child: AppPressable(
        tooltip: context.strings.dialogCloseTooltip(),
        onTap: Get.find<OverlayController>().close,
        borderRadius: AppRadii.full,
        builder: (context, hovered) => Container(
          padding: const EdgeInsets.all(AppSpacing.s5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hovered ? c.secondary : null,
          ),
          child: Icon(AppIcons.x, size: 21, color: c.muted),
        ),
      ),
    );
  }
}

/// `.modal>p`: muted, line height 1.5, 20 px below.
class ModalParagraph extends StatelessWidget {
  const ModalParagraph(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppCheckoutSizes.modalParagraphMarginBottom,
      ),
      child: Text(
        text,
        style: context.text
            .of(AppFontSize.s14, height: AppLineHeight.modalBody)
            .copyWith(color: context.colors.muted),
      ),
    );
  }
}
