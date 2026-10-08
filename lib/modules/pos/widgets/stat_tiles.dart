import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/qty_formatter.dart';
import '../../../shared/widgets/stat_tile.dart';
import '../controllers/cart_controller.dart';

/// Total Items, Total Qty and Total Value under the cart (`.stat-tiles`), read
/// from the totals the cart controller computed once per change.
class StatTiles extends StatelessWidget {
  const StatTiles({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    final s = context.strings;
    final cart = Get.find<CartController>();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadii.r11),
      ),
      child: Padding(
        padding: EdgeInsets.all(m.statTilesPad),
        child: Obx(() {
          final t = cart.totals.value;
          return Row(
            children: <Widget>[
              Expanded(
                flex: 100,
                child: StatTile(
                  icon: AppIcons.shoppingCart,
                  iconColor: c.blue,
                  iconSize: m.statTileIcon,
                  label: s.statTotalItems(),
                  value: '${t.items}',
                  valueFontSize: m.statTileValueFont,
                  padY: m.statTilePadY,
                  padX: m.statTilePadX,
                  gap: m.statTileGap,
                  showIcon: m.showStatTileIcon,
                  vertical: m.statTilesVertical,
                ),
              ),
              SizedBox(width: m.statTilesGap),
              Expanded(
                flex: 100,
                child: StatTile(
                  icon: AppIcons.packageBox,
                  iconColor: c.text,
                  iconSize: m.statTileIcon,
                  label: s.statTotalQty(),
                  value: QtyFormatter.fixed3(t.qty),
                  valueFontSize: m.statTileValueFont,
                  padY: m.statTilePadY,
                  padX: m.statTilePadX,
                  gap: m.statTileGap,
                  showIcon: m.showStatTileIcon,
                  vertical: m.statTilesVertical,
                ),
              ),
              SizedBox(width: m.statTilesGap),
              Expanded(
                flex: 125,
                child: StatTile(
                  icon: AppIcons.indianRupee,
                  iconColor: c.greenIcon,
                  iconSize: m.statTileIcon,
                  label: s.statTotalValue(),
                  value: MoneyFormatter.format(t.value, symbol: false),
                  valueFontSize: m.statTileValueFont,
                  padY: m.statTilePadY,
                  padX: m.statTilePadX,
                  gap: m.statTileGap,
                  showIcon: m.showStatTileIcon,
                  vertical: m.statTilesVertical,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
