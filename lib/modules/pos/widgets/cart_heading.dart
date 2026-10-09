import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/controllers/clock_controller.dart';
import '../../shell/controllers/settings_controller.dart';
import 'order_menu.dart';
import 'sale_toggle.dart';

/// `.cart-heading`: cart icon, counter name, sale toggle, the clock and the
/// order menu (the clock and the menu both have `margin-left:auto`, so the
/// free space is split between them).
class CartHeading extends StatefulWidget {
  const CartHeading({super.key});

  @override
  State<CartHeading> createState() => _CartHeadingState();
}

class _CartHeadingState extends State<CartHeading> {
  late final ClockController _clock = Get.find<ClockController>();

  @override
  void initState() {
    super.initState();
    _clock.attach();
  }

  @override
  void dispose() {
    _clock.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    final settings = Get.find<SettingsController>();
    final timeText = Obx(() {
      // `now` only signals the tick; the text shows the real time, so it is
      // right even on the first build after the clock was idle.
      _clock.now.value;
      return Text(
        DateFormatter.dateTime(_clock.current),
        maxLines: 1,
        softWrap: false,
        style: context.text
            .fluid(m.cartTimeFont, height: AppLineHeight.base)
            .copyWith(color: c.muted),
      );
    });
    // `.cart-heading` is a flex row with `gap`: the icon, counter and the
    // sale toggle sit at the left (the toggle never shrinks), the clock and
    // the menu button carry `margin-left:auto`, so the free space is shared
    // equally before the clock and before the menu. Where the row is too
    // narrow the whole row scales down instead of wrapping (KG-111).
    final left = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(AppIcons.shoppingCart, size: m.cartHeadingIcon, color: c.blue),
        SizedBox(width: m.cartHeadingGap),
        Obx(
          () => Text(
            settings.settings.value.counter,
            style: context.text
                .fluid(
                  m.cartHeadingFont,
                  weight: AppFontWeight.bold,
                  height: AppLineHeight.base,
                )
                .copyWith(color: c.text),
          ),
        ),
        SizedBox(width: m.cartHeadingGap),
        const SaleToggle(),
      ],
    );
    final firstRow = LayoutBuilder(
      builder: (context, constraints) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              left,
              if (!m.cartTimeOnOwnRow) timeText,
              const OrderMenu(),
            ],
          ),
        ),
      ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: m.cartHeadingMinHeight),
      // At width <= 1280 the clock wraps to its own row (`order:5; flex-basis
      // 100%; padding: 2px 0`).
      child: m.cartTimeOnOwnRow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                firstRow,
                SizedBox(height: m.cartHeadingGap),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                  child: timeText,
                ),
              ],
            )
          : firstRow,
    );
  }
}
