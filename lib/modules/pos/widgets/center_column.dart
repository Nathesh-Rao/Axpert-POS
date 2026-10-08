import 'package:flutter/material.dart';

import '../../../core/responsive/app_metrics_scope.dart';
import '../../../shared/widgets/app_panel.dart';
import 'cart_actions_bar.dart';
import 'cart_heading.dart';
import 'cart_table.dart';
import 'stat_tiles.dart';

/// `.center-column`: the cart panel over the stat tiles, shown while the cart
/// has lines.
class CenterColumn extends StatelessWidget {
  const CenterColumn({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: AppPanel(
            padding: EdgeInsets.all(m.panelPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const CartHeading(),
                SizedBox(height: m.cartTableMarginTop),
                const Expanded(child: CartTable()),
                const CartActionsBar(),
              ],
            ),
          ),
        ),
        SizedBox(height: m.layoutGap),
        const StatTiles(),
      ],
    );
  }
}
