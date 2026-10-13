import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../shell/views/app_shell.dart';
import '../controllers/cart_controller.dart';
import '../widgets/catalog_panel.dart';
import '../widgets/center_column.dart';
import '../widgets/desktop_cart_column.dart';
import '../widgets/products_tab.dart';
import '../controllers/products_panel_controller.dart';
import '../../../core/theme/tokens/app_density_sizes.dart';
import '../../../core/theme/tokens/app_motion.dart';
import '../../../core/theme/tokens/app_spacing.dart';

/// POS page: the catalog, plus the center column (cart) once the cart has
/// lines. The catalog keeps its slot, so its scroll and text survive the
/// switch. Grid columns follow `.main` (catalog 2fr, center 3fr).
class PosView extends StatelessWidget {
  const PosView({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final gap = context.metrics.layoutGap;
    if (!context.metrics.touch) {
      return const AppShell(page: AppPage.pos, child: _DesktopPos());
    }
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

/// Desktop POS page (DEC-138): a slim Products tab, the Products panel (pushes
/// the cart when expanded, nothing when collapsed) and the cart, which takes
/// the rest of the width. Tab order: tab, panel, cart.
class _DesktopPos extends StatelessWidget {
  const _DesktopPos();

  @override
  Widget build(BuildContext context) {
    final panel = Get.find<ProductsPanelController>();
    final gap = context.metrics.layoutGap;
    final animate = !MediaQuery.disableAnimationsOf(context);
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: LayoutBuilder(
        builder: (context, constraints) => Obx(() {
          final open = panel.isOpen;
          const lead = AppDensitySizes.productsTabWidth + AppSpacing.s8;
          final width =
              (constraints.maxWidth * AppDensitySizes.productsPanelFraction)
                  .clamp(
                    AppDensitySizes.productsPanelMin,
                    AppDensitySizes.productsPanelMax,
                  );
          // Push the cart while it keeps its minimum width; on narrow windows
          // the panel opens over the cart instead.
          final push =
              constraints.maxWidth - lead - width - gap >=
              AppDensitySizes.cartMinWidth;
          const catalog = _Pane(order: 1, child: CatalogPanel());
          final duration = Duration(
            milliseconds: animate ? AppMotion.buttonMs : 0,
          );
          return Stack(
            children: <Widget>[
              Row(
                children: <Widget>[
                  const _Pane(order: 0, child: ProductsTab()),
                  const SizedBox(width: AppSpacing.s8),
                  AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeOut,
                    width: open && push ? width + gap : 0,
                    child: open && push
                        ? ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.centerLeft,
                              minWidth: width,
                              maxWidth: width,
                              child: Padding(
                                padding: EdgeInsets.only(right: gap),
                                child: catalog,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const Expanded(
                    child: _Pane(order: 2, child: DesktopCartColumn()),
                  ),
                ],
              ),
              if (open && !push)
                const Positioned(
                  left: lead,
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: catalog,
                ),
            ],
          );
        }),
      ),
    );
  }
}
