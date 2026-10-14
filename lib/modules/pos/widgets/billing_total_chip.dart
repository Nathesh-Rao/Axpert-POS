import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_density_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../controllers/payment_controller.dart';
import '../controllers/pos_work_view_controller.dart';
import 'products_shortcut_label.dart';

/// The cart footer's invoice total while Billing is collapsed (DEC-141): the
/// same total the Bill Summary shows, bold, as a button that opens Billing
/// again (and with it the way to pay).
class BillingTotalChip extends StatelessWidget {
  const BillingTotalChip({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final payment = Get.find<PaymentController>();
    final work = Get.find<PosWorkViewController>();
    final shortcut = billingShortcutLabel(context);
    return Obx(() {
      final total = MoneyFormatter.format(payment.total);
      return AppPressable(
        onTap: work.openBilling,
        tooltip: s.billingChipTooltip(shortcut),
        semanticLabel: s.billingChipSemantic(total),
        borderRadius: AppRadii.r8,
        builder: (context, hovered) => Container(
          height: AppDensitySizes.billingChipHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10),
          decoration: BoxDecoration(
            color: hovered ? c.secondary : c.actionBlueBg,
            borderRadius: BorderRadius.circular(AppRadii.r8),
            border: Border.all(color: c.blue),
          ),
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      total,
                      maxLines: 1,
                      softWrap: false,
                      style: context.text
                          .of(
                            AppFontSize.s16,
                            weight: AppFontWeight.bold,
                            height: AppLineHeight.base,
                          )
                          .copyWith(color: c.actionBlueFg),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s6),
                Icon(
                  AppIcons.chevronLeft,
                  size: AppDensitySizes.footerIcon,
                  color: c.actionBlueFg,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
