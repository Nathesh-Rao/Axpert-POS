import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../shell/views/app_shell.dart';
import '../controllers/cart_controller.dart';
import '../widgets/catalog_panel.dart';
import '../widgets/center_column.dart';

/// POS page: the catalog, plus the center column (cart) once the cart has
/// lines. The catalog keeps its slot, so its scroll and text survive the
/// switch. Grid columns follow `.main` (catalog 2fr, center 3fr).
class PosView extends StatelessWidget {
  const PosView({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final gap = context.metrics.layoutGap;
    return AppShell(
      page: AppPage.pos,
      child: Obx(() {
        final active = cart.active.value;
        // Tab goes through the whole catalog, then the cart column (DOM order).
        return FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Row(
            children: <Widget>[
              const Expanded(
                flex: 2,
                child: _Pane(order: 0, child: CatalogPanel()),
              ),
              if (active) ...<Widget>[
                SizedBox(width: gap),
                const Expanded(
                  flex: 3,
                  child: _Pane(order: 1, child: CenterColumn()),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({required this.order, required this.child});

  final double order;
  final Widget child;

  @override
  Widget build(BuildContext context) => FocusTraversalOrder(
    order: NumericFocusOrder(order),
    child: FocusTraversalGroup(child: child),
  );
}
