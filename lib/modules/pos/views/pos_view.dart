import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/app_panel.dart';
import '../../shell/views/app_shell.dart';
import '../controllers/cart_controller.dart';
import '../widgets/catalog_panel.dart';

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
        return Row(
          children: <Widget>[
            const Expanded(flex: 2, child: CatalogPanel()),
            if (active) ...<Widget>[
              SizedBox(width: gap),
              const Expanded(
                flex: 3,
                child: SizedBox.expand(child: AppPanel()),
              ),
            ],
          ],
        );
      }),
    );
  }
}
