import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../shell/views/app_shell.dart';
import '../controllers/cart_controller.dart';
import '../widgets/catalog_panel.dart';
import '../widgets/center_column.dart';
import '../widgets/desktop_cart_column.dart';
import '../widgets/work_tab.dart';
import '../controllers/pos_work_view_controller.dart';
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

/// Desktop POS page (DEC-139): the edge tab and ONE work-area view at a time,
/// the catalog or the cart, each over the whole width. Switching expands the
/// shown view and shrinks the other (clipping only, no re-layout of the
/// content), and is instant under `disableAnimations`.
class _DesktopPos extends StatelessWidget {
  const _DesktopPos();

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: const Row(
        children: <Widget>[
          _Pane(order: 0, child: WorkTab()),
          SizedBox(width: AppSpacing.s8),
          Expanded(child: _WorkArea()),
        ],
      ),
    );
  }
}

class _WorkArea extends StatelessWidget {
  const _WorkArea();

  @override
  Widget build(BuildContext context) {
    final work = Get.find<PosWorkViewController>();
    final animate = !MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Obx(() {
          final catalog = work.inCatalog;
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(end: catalog ? 1 : 0),
            duration: Duration(milliseconds: animate ? AppMotion.buttonMs : 0),
            curve: Curves.easeOut,
            builder: (context, t, _) => Row(
              children: <Widget>[
                _Slot(
                  width: width,
                  factor: t,
                  shown: catalog,
                  alignment: Alignment.centerLeft,
                  order: 1,
                  child: const CatalogPanel(),
                ),
                _Slot(
                  width: width,
                  factor: 1 - t,
                  shown: !catalog,
                  alignment: Alignment.centerRight,
                  order: 2,
                  child: const DesktopCartColumn(),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

/// One view: laid out at the full [width] and revealed by [factor] (0 hides
/// it completely: no pointer, focus or semantics).
class _Slot extends StatelessWidget {
  const _Slot({
    required this.width,
    required this.factor,
    required this.shown,
    required this.alignment,
    required this.order,
    required this.child,
  });

  final double width;
  final double factor;

  /// The view the user is switching to: it is live from the first frame of
  /// the transition (the focus moves into it), even while its factor is 0.
  final bool shown;
  final Alignment alignment;
  final double order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hidden = !shown && factor <= 0.0001;
    return ClipRect(
      child: Align(
        alignment: alignment,
        widthFactor: factor,
        child: SizedBox(
          width: width,
          child: ExcludeSemantics(
            excluding: hidden,
            child: ExcludeFocus(
              excluding: hidden,
              child: IgnorePointer(
                ignoring: hidden,
                child: TickerMode(
                  enabled: !hidden,
                  child: _Pane(order: order, child: child),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
