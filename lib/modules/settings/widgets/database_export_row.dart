import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../controllers/database_export_controller.dart';

/// Settings row "Export database" (admin only; nothing is shown otherwise).
class DatabaseExportRow extends StatelessWidget {
  const DatabaseExportRow({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<DatabaseExportController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<DatabaseExportController>();
    final c = context.colors;
    final s = context.strings;
    return Obx(() {
      if (!controller.canExport) return const SizedBox.shrink();
      final busy = controller.busy.value;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s22),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: <Widget>[
            Icon(AppIcons.download, size: 21, color: c.text),
            const SizedBox(width: AppSpacing.s13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    s.exportDbTitle(),
                    style: context.text
                        .of(AppFontSize.s14)
                        .copyWith(color: c.text),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  Text(
                    s.exportDbHint(),
                    style: context.text
                        .of(AppFontSize.s12)
                        .copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s20),
            Opacity(
              opacity: busy ? AppCheckoutSizes.disabledOpacity : 1,
              child: AppPressable(
                borderRadius: AppRadii.r8,
                onTap: busy ? null : controller.requestExport,
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
                    busy ? s.exportDbExporting() : s.exportDbButton(),
                    style: context.text
                        .of(AppFontSize.s14, weight: AppFontWeight.medium)
                        .copyWith(color: c.text),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
