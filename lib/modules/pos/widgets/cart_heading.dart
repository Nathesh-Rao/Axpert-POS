import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/controllers/clock_controller.dart';
import '../../shell/controllers/settings_controller.dart';

/// `.cart-heading`: cart icon, counter name and the clock. The sale toggle and
/// the order menu arrive in S4 (the clock keeps its `margin-left:auto`).
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
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: m.cartHeadingMinHeight),
      child: Row(
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
          const Spacer(),
          Obx(
            () => Text(
              DateFormatter.dateTime(_clock.now.value),
              maxLines: 1,
              softWrap: false,
              style: context.text
                  .fluid(m.cartTimeFont, height: AppLineHeight.base)
                  .copyWith(color: c.muted),
            ),
          ),
        ],
      ),
    );
  }
}
