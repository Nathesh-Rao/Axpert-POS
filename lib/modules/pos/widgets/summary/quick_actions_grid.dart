import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/responsive/app_metrics_scope.dart';
import '../../../../core/shortcuts/shortcut_controller.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../core/theme/tokens/app_icons.dart';
import '../../../../core/theme/tokens/app_sizes.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../shared/controllers/overlay_controller.dart';
import '../../../../shared/controllers/toast_controller.dart';
import '../../../../shared/widgets/action_button.dart';
import '../../../../shared/widgets/app_pressable.dart';
import '../../controllers/cart_actions_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/held_bills_controller.dart';

/// `.quick-actions`: eight icon tiles in 4 columns x 2 rows with tooltips
/// (the F-key is part of the title). Hold count badge on Recall, red dot on
/// Discount while a discount applies, clock on Clear Hold.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final sm = context.metrics.summary;
    final s = context.strings;
    final overlay = Get.find<OverlayController>();
    final shortcuts = Get.find<ShortcutController>();
    final held = Get.find<HeldBillsController>();
    final cart = Get.find<CartController>();

    String title(String label, String? key) =>
        key == null ? label : s.actionTitleWithKey(label: label, key: key);

    final tiles = <Widget>[
      _Tile(
        label: s.actionDiscount(),
        title: title(s.actionDiscount(), 'F6'),
        icon: AppIcons.percent,
        tone: ActionTone.red,
        size: sm.quickActionSize,
        onTap: () => shortcuts.run(ShortcutAction.discount),
        decoration: Obx(
          () => cart.totals.value.discount.isZero
              ? const SizedBox.shrink()
              : const _DiscountDot(),
        ),
      ),
      _Tile(
        label: s.actionPriceCheck(),
        title: title(s.actionPriceCheck(), null),
        icon: AppIcons.search,
        tone: ActionTone.blue,
        size: sm.quickActionSize,
        onTap: () => overlay.open('priceCheck'),
      ),
      _Tile(
        label: s.actionHold(),
        title: title(s.actionHold(), 'F4'),
        icon: AppIcons.pauseCircle,
        tone: ActionTone.orange,
        size: sm.quickActionSize,
        onTap: () => shortcuts.run(ShortcutAction.hold),
      ),
      _Tile(
        label: s.actionClearHold(),
        title: title(s.actionClearHold(), null),
        icon: AppIcons.trash2,
        tone: ActionTone.red,
        size: sm.quickActionSize,
        onTap: () =>
            overlay.openConfirm(s.confirmDeleteHeld(count: held.count), () {
              held.clearAll();
              Get.find<ToastController>().show(s.toastHeldCleared());
            }),
        decoration: const _ClearHoldClock(),
      ),
      _Tile(
        label: s.actionRecall(),
        title: title(s.actionRecall(), 'F5'),
        icon: AppIcons.rotateCcw,
        tone: ActionTone.purple,
        size: sm.quickActionSize,
        onTap: () => shortcuts.run(ShortcutAction.recall),
        decoration: Obx(
          () => held.count == 0
              ? const SizedBox.shrink()
              : _Badge(count: held.count),
        ),
      ),
      _Tile(
        label: s.actionReprint(),
        title: title(s.actionReprint(), null),
        icon: AppIcons.printer,
        tone: ActionTone.blue,
        size: sm.quickActionSize,
        onTap: () => overlay.open('reprint'),
      ),
      _Tile(
        label: s.actionClear(),
        title: title(s.actionClear(), null),
        icon: AppIcons.x,
        tone: ActionTone.red,
        size: sm.quickActionSize,
        onTap: () => overlay.openConfirm(
          s.confirmClearCart(),
          Get.find<CartActionsController>().clear,
        ),
      ),
      _Tile(
        label: s.actionClose(),
        title: title(s.actionClose(), null),
        icon: AppIcons.power,
        tone: ActionTone.neutral,
        size: sm.quickActionSize,
        onTap: () => overlay.open('close'),
      ),
    ];
    Widget row(List<Widget> items) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        for (final tile in items) Expanded(child: Center(child: tile)),
      ],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        row(tiles.sublist(0, 4)),
        SizedBox(height: sm.quickActionsGap),
        row(tiles.sublist(4)),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.title,
    required this.icon,
    required this.tone,
    required this.size,
    required this.onTap,
    this.decoration,
  });

  final String label;
  final String title;
  final IconData icon;
  final ActionTone tone;
  final double size;
  final VoidCallback onTap;
  final Widget? decoration;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, hover) = switch (tone) {
      ActionTone.blue => (c.actionBlueBg, c.actionBlueFg, c.actionBlueHover),
      ActionTone.red => (c.actionRedBg, c.actionRedFg, c.actionRedHover),
      ActionTone.purple => (
        c.actionPurpleBg,
        c.actionPurpleFg,
        c.actionPurpleHover,
      ),
      ActionTone.orange => (
        c.actionOrangeBg,
        c.actionOrangeFg,
        c.actionOrangeHover,
      ),
      ActionTone.neutral => (
        c.actionNeutralBg,
        c.actionNeutralFg,
        c.actionNeutralHover,
      ),
    };
    return AppPressable(
      onTap: onTap,
      tooltip: title,
      semanticLabel: label,
      borderRadius: AppCheckoutSizes.quickActionRadius,
      builder: (context, hovered) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: hovered ? hover : bg,
                  borderRadius: BorderRadius.circular(
                    AppCheckoutSizes.quickActionRadius,
                  ),
                ),
                child: Center(
                  child: Icon(icon, size: AppSizes.quickActionIcon, color: fg),
                ),
              ),
            ),
            if (decoration != null) Positioned.fill(child: decoration!),
          ],
        ),
      ),
    );
  }
}

class _DiscountDot extends StatelessWidget {
  const _DiscountDot();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          right: AppCheckoutSizes.dotRight,
          top: AppCheckoutSizes.dotTop,
          child: Container(
            width: AppSizes.discountDot,
            height: AppSizes.discountDot,
            decoration: BoxDecoration(
              color: c.discountDot,
              shape: BoxShape.circle,
              border: Border.all(
                color: c.card,
                width: AppCheckoutSizes.dotRing,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClearHoldClock extends StatelessWidget {
  const _ClearHoldClock();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          right: AppCheckoutSizes.clockRight,
          bottom: AppCheckoutSizes.clockBottom,
          child: Container(
            width: AppCheckoutSizes.clockSize,
            height: AppCheckoutSizes.clockSize,
            decoration: BoxDecoration(
              color: c.clearHoldClock,
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.clock,
              size: AppCheckoutSizes.clockSize,
              color: c.actionRedFg,
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          right: AppCheckoutSizes.badgeOffset,
          top: AppCheckoutSizes.badgeOffset,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: AppCheckoutSizes.badgeSize,
              minHeight: AppCheckoutSizes.badgeSize,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.smallBadge,
              shape: BoxShape.circle,
              border: Border.all(
                color: c.card,
                width: AppCheckoutSizes.badgeBorder,
              ),
            ),
            child: Text(
              context.strings.countBadge(count),
              style: context.text
                  .fluid(AppCheckoutSizes.badgeFont, weight: AppFontWeight.bold)
                  .copyWith(color: c.white),
            ),
          ),
        ),
      ],
    );
  }
}
