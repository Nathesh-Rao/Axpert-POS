import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/app_panel.dart';
import '../../../core/theme/tokens/app_density_sizes.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../../pos/controllers/pos_work_view_controller.dart';
import '../../pos/widgets/products_shortcut_label.dart';
import '../../pos/widgets/summary/bill_summary_body.dart';
import '../../../core/theme/tokens/app_icons.dart';

/// The right-hand Bill Summary panel: title plus the checkout cards (S4.a).
/// Width: 380 on POS, 310 elsewhere (KG-029). On the desktop POS page the
/// panel can be collapsed (DEC-141): [collapsible] adds the button that hides it.
class BillSummaryFrame extends StatelessWidget {
  const BillSummaryFrame({
    required this.isPos,
    this.collapsible = false,
    super.key,
  });

  final bool isPos;
  final bool collapsible;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    return SizedBox(
      width: m.summaryWidth(isPos: isPos),
      child: AppPanel(
        padding: EdgeInsets.all(m.billSummaryPad),
        child: BillSummaryBody(
          title: SizedBox(
            height: m.summary.titleHeight,
            child: Row(
              children: <Widget>[
                Icon(AppIcons.fileText, size: 23, color: c.blue),
                const SizedBox(width: AppSpacing.s12),
                Flexible(
                  child: Text(
                    context.strings.billSummaryTitle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text
                        .fluid(
                          m.billSummaryTitleFont,
                          weight: AppFontWeight.bold,
                          height: AppLineHeight.summaryTitle,
                        )
                        .copyWith(color: c.text),
                  ),
                ),
                if (collapsible) ...<Widget>[
                  const SizedBox(width: AppSpacing.s8),
                  const _CollapseButton(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hides Billing (the same as Ctrl/Cmd+.).
class _CollapseButton extends StatelessWidget {
  const _CollapseButton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = context.strings.billingCollapseTooltip(
      billingShortcutLabel(context),
    );
    return AppPressable(
      onTap: Get.find<PosWorkViewController>().closeBilling,
      tooltip: label,
      semanticLabel: label,
      borderRadius: AppRadii.r8,
      builder: (context, hovered) => Container(
        width: AppDensitySizes.billingToggleSize,
        height: AppDensitySizes.billingToggleSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hovered ? c.secondary : null,
          borderRadius: BorderRadius.circular(AppRadii.r8),
        ),
        child: Icon(
          AppIcons.panelRightClose,
          size: AppDensitySizes.productsTabIcon,
          color: c.muted,
        ),
      ),
    );
  }
}
