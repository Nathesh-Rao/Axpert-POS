import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/shortcuts/shortcut_controller.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_density_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/qty_formatter.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/widgets/action_button.dart';
import '../controllers/cart_actions_controller.dart';
import '../controllers/cart_controller.dart';

/// The one-row footer of the desktop cart: the totals (items, quantity, value;
/// the same numbers as the stat tiles) on the left, the four cart actions as
/// compact buttons on the right. Below `cartNarrowBreak` the buttons show only
/// their icon (the label stays the tooltip and the semantic label).
class CartFooter extends StatelessWidget {
  const CartFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final cart = Get.find<CartController>();
    final overlay = Get.find<OverlayController>();
    final shortcuts = Get.find<ShortcutController>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < AppDensitySizes.cartNarrowBreak;
        Widget button(
          String label,
          IconData icon,
          ActionTone tone,
          VoidCallback f, {
          String? key,
        }) => Padding(
          padding: const EdgeInsets.only(left: AppSpacing.s6),
          child: ActionButton(
            label: label,
            icon: icon,
            tone: tone,
            onTap: f,
            fit: true,
            iconOnly: narrow,
            tooltip: key == null ? label : s.actionWithKey(label, key),
            height: AppDensitySizes.footerButtonHeight,
            iconSize: AppDensitySizes.footerIcon,
            fontSize: AppFontSize.s12.px,
          ),
        );
        return Container(
          height: AppDensitySizes.cartFooterHeight,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: c.border,
                width: AppDensitySizes.cartRowHairline,
              ),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Obx(() {
                  final t = cart.totals.value;
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _Total(
                          label: s.statTotalItems(),
                          icon: AppIcons.shoppingCart,
                          color: c.blue,
                          value: '${t.items}',
                        ),
                        const SizedBox(width: AppSpacing.s16),
                        _Total(
                          label: s.statTotalQty(),
                          icon: AppIcons.packageBox,
                          color: c.text,
                          value: QtyFormatter.fixed3(t.qty),
                        ),
                        const SizedBox(width: AppSpacing.s16),
                        _Total(
                          label: s.statTotalValue(),
                          icon: AppIcons.currencyGlyph(t.value.currency.code),
                          iconText: t.value.currency.symbol,
                          color: c.greenIcon,
                          value: MoneyFormatter.format(t.value, symbol: false),
                        ),
                      ],
                    ),
                  );
                }),
              ),
              button(
                s.actionClearCart(),
                AppIcons.trash2,
                ActionTone.red,
                () => overlay.openConfirm(
                  s.confirmClearCart(),
                  Get.find<CartActionsController>().clear,
                ),
              ),
              button(
                s.actionHold(),
                AppIcons.pauseCircle,
                ActionTone.blue,
                () => shortcuts.run(ShortcutAction.hold),
                key: s.keyFunction(4),
              ),
              button(
                s.actionRecall(),
                AppIcons.rotateCcw,
                ActionTone.purple,
                () => shortcuts.run(ShortcutAction.recall),
                key: s.keyFunction(5),
              ),
              button(
                s.actionPriceCheck(),
                AppIcons.search,
                ActionTone.blue,
                () => overlay.open('priceCheck'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// `<icon> <value>` with the label as tooltip and semantic label.
class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    this.iconText,
  });

  final String label;
  final IconData? icon;
  final String? iconText;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mark = icon != null
        ? Icon(icon, size: AppDensitySizes.footerIcon, color: color)
        : Text(
            iconText!.trim(),
            style: context.text
                .of(AppFontSize.s13, weight: AppFontWeight.bold)
                .copyWith(color: color),
          );
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        value: value,
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              mark,
              const SizedBox(width: AppSpacing.s6),
              Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: context.text
                    .of(
                      AppFontSize.s14,
                      weight: AppFontWeight.bold,
                      height: AppLineHeight.base,
                    )
                    .copyWith(color: c.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
