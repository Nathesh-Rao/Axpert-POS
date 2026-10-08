import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/app_pressable.dart';

String placeholderDialogTitle(AppStrings s, String id) => switch (id) {
  'scan' => s.scanTooltip(),
  'profile' => s.menuProfile(),
  'settings' => s.menuSettings(),
  'shortcuts' => s.menuShortcuts(),
  'priceCheck' => s.actionPriceCheck(),
  'discount' => s.actionDiscount(),
  'recall' => s.actionRecall(),
  'reprint' => s.actionReprint(),
  'close' => s.actionClose(),
  'addCustomer' => s.addCustomerTooltip(),
  'customers' => s.customerSearchTooltip(),
  'counter' => s.orderRename(),
  'note' => s.orderAddNote(),
  'receipt' => s.orderPrintDraft(),
  _ => s.menuLogout(),
};

/// Stand-in for the real modals (scan simulator S4, profile/settings S5,
/// shortcuts help S4, shift close S5): title, one line, Close.
class PlaceholderDialog extends StatelessWidget {
  const PlaceholderDialog({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    return AppModal(
      title: placeholderDialogTitle(s, id),
      children: <Widget>[
        Text(
          s.placeholderDialogBody(),
          style: context.text
              .of(AppFontSize.s14, height: AppLineHeight.modalBody)
              .copyWith(color: c.muted),
        ),
        const SizedBox(height: AppSpacing.s20),
        Align(
          alignment: Alignment.centerRight,
          child: AppPressable(
            borderRadius: AppRadii.r8,
            onTap: Get.find<OverlayController>().close,
            builder: (context, hovered) => ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.controlMinHeight,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: hovered ? c.secondary : c.card,
                  borderRadius: BorderRadius.circular(AppRadii.r8),
                  border: Border.all(color: c.border),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s20,
                    ),
                    child: Text(
                      s.dialogClose(),
                      style: context.text
                          .of(AppFontSize.s14, weight: AppFontWeight.semiBold)
                          .copyWith(color: c.text),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
