import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/shortcuts/shortcut_controller.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/widgets/action_button.dart';
import '../controllers/cart_actions_controller.dart';

/// `.cart-actions`: Clear Cart, Hold, Recall, Price Check. Clear works now;
/// Hold, Recall and Price Check behave like F4, F5 and the placeholder dialog
/// until S4.
class CartActionsBar extends StatelessWidget {
  const CartActionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final s = context.strings;
    final overlay = Get.find<OverlayController>();
    final shortcuts = Get.find<ShortcutController>();
    Widget button(
      String label,
      IconData icon,
      ActionTone tone,
      VoidCallback f,
    ) => Expanded(
      child: ActionButton(
        label: label,
        icon: icon,
        tone: tone,
        onTap: f,
        height: AppSizes.cartActionHeight,
        iconSize: m.cartActionIcon,
        fontSize: AppFontSize.s12.px,
      ),
    );
    const gap = SizedBox(width: AppSizes.cartActionsGap);
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.cartActionsMarginTop),
      child: Row(
        children: <Widget>[
          button(
            s.actionClearCart(),
            AppIcons.trash2,
            ActionTone.red,
            () => overlay.openConfirm(
              s.confirmClearCart(),
              Get.find<CartActionsController>().clear,
            ),
          ),
          gap,
          button(
            s.actionHold(),
            AppIcons.pauseCircle,
            ActionTone.blue,
            () => shortcuts.run(ShortcutAction.hold),
          ),
          gap,
          button(
            s.actionRecall(),
            AppIcons.rotateCcw,
            ActionTone.purple,
            () => shortcuts.run(ShortcutAction.recall),
          ),
          gap,
          button(
            s.actionPriceCheck(),
            AppIcons.search,
            ActionTone.blue,
            () => overlay.open('priceCheck'),
          ),
        ],
      ),
    );
  }
}
