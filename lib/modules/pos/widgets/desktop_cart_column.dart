import 'package:flutter/material.dart';

import '../../../core/responsive/app_metrics_scope.dart';
import '../../../shared/widgets/app_panel.dart';
import 'cart_compact_table.dart';
import 'cart_footer.dart';
import 'cart_heading.dart';
import 'customer_row.dart';

/// The cart of the desktop layout (DEC-138): heading, customer row, the
/// compact table and the one-row footer, all in one panel. It is present even
/// when the cart is empty (the table then shows what to do next).
class DesktopCartColumn extends StatelessWidget {
  const DesktopCartColumn({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    return AppPanel(
      padding: EdgeInsets.all(m.panelPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const CartHeading(),
          const CustomerRow(),
          SizedBox(height: m.cartTableMarginTop),
          const Expanded(child: CartCompactTable()),
          SizedBox(height: m.cartTableMarginTop),
          const CartFooter(),
        ],
      ),
    );
  }
}
