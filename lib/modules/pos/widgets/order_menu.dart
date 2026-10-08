import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/controllers/shell_chrome_controller.dart';
import '../../../shared/widgets/app_popover.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../controllers/order_menu_controller.dart';

/// The "..." button of the cart heading and its popover.
class OrderMenu extends StatelessWidget {
  const OrderMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final chrome = Get.find<ShellChromeController>();
    final menu = Get.find<OrderMenuController>();
    Widget item(String label, VoidCallback onTap) => AppPressable(
      borderRadius: AppRadii.r6,
      semanticLabel: label,
      onTap: onTap,
      builder: (context, hovered) => Container(
        padding: const EdgeInsets.all(AppSpacing.s11),
        decoration: BoxDecoration(
          color: hovered ? c.secondary : null,
          borderRadius: BorderRadius.circular(AppRadii.r6),
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: context.text.of(AppFontSize.s14).copyWith(color: c.text),
        ),
      ),
    );
    return Obx(
      () => AppPopover(
        open: chrome.menu.value == ShellMenu.order,
        padding: const EdgeInsets.all(AppSpacing.s7),
        anchor: AppPressable(
          tooltip: s.orderOptionsTooltip(),
          borderRadius: AppRadii.r6,
          onTap: chrome.toggleOrderMenu,
          builder: (context, hovered) => Padding(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: Icon(
              AppIcons.ellipsis,
              size: AppCheckoutSizes.orderMenuIcon,
              color: c.text,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            item(s.orderRename(), menu.renameCounter),
            item(s.orderAddNote(), menu.addNote),
            item(s.orderPrintDraft(), menu.printDraft),
          ],
        ),
      ),
    );
  }
}
