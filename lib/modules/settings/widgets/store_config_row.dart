import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/session/permissions.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../features/session/presentation/controllers/active_session.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/widgets/app_pressable.dart';

/// Settings row "Store configuration" (admin edits, manager views; a cashier
/// does not see it).
class StoreConfigRow extends StatelessWidget {
  const StoreConfigRow({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ActiveSession>()) return const SizedBox.shrink();
    final session = Get.find<ActiveSession>();
    final c = context.colors;
    final s = context.strings;
    return Obx(() {
      if (!StoreConfigPermissions.canView(session.user.value?.role) ||
          session.store.value == null) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s22),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: <Widget>[
            Icon(AppIcons.percent, size: 21, color: c.text),
            const SizedBox(width: AppSpacing.s13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    s.scTitle(),
                    style: context.text
                        .of(AppFontSize.s14)
                        .copyWith(color: c.text),
                  ),
                  const SizedBox(height: AppSpacing.s5),
                  Text(
                    s.scSettingsHint(),
                    style: context.text
                        .of(AppFontSize.s12)
                        .copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s20),
            AppPressable(
              borderRadius: AppRadii.r8,
              onTap: () {
                final overlay = Get.find<OverlayController>();
                if (overlay.isOpen) overlay.close();
                Get.offAllNamed<void>(AppRoutes.storeConfig);
              },
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
                  s.scOpen(),
                  style: context.text
                      .of(AppFontSize.s14, weight: AppFontWeight.medium)
                      .copyWith(color: c.text),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
