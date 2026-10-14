import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../shell/views/app_shell.dart';
import '../controllers/cart_controller.dart';
import '../widgets/catalog_panel.dart';
import '../widgets/center_column.dart';
import '../widgets/desktop_cart_column.dart';
import '../widgets/products_edge_control.dart';
import '../../shell/widgets/bill_summary_frame.dart';
import '../models/pos_panel_layout.dart';
import '../../../core/theme/tokens/app_density_sizes.dart';
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

/// Desktop POS page (DEC-141): the edge control, then Products | Cart |
/// Billing. Each panel has size states (Products hidden, 25%, 75%; Billing
/// open or collapsed) and the cart takes the rest; `PanelGeometry` holds the
/// width math and the fallback for small windows. A state change animates the
/// widths (180 ms, instant under `disableAnimations`). All panels stay mounted,
/// so the catalog keeps its scroll and search text and the cart its scroll.
class _DesktopPos extends StatefulWidget {
  const _DesktopPos();

  @override
  State<_DesktopPos> createState() => _DesktopPosState();
}

class _DesktopPosState extends State<_DesktopPos> {
  late final PosWorkViewController _work = Get.find<PosWorkViewController>();

  /// The layout drawn last: a change of the window alone must not animate
  /// (the panels would trail behind the window edge).
  PanelLayout? _drawn;

  @override
  void dispose() {
    _work.geometry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final animate = !MediaQuery.disableAnimationsOf(context);
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final geometry = PanelGeometry(
            workWidth: constraints.maxWidth,
            billingWidth: m.summaryWidth(isPos: true),
            gap: m.layoutGap,
            edgeWidth: AppDensitySizes.productsTabWidth,
            edgeGap: AppSpacing.s8,
            cartMinWide: AppDensitySizes.cartMinWide,
            cartMinNarrow: AppDensitySizes.cartMinNarrow,
            productsMinNarrow: AppDensitySizes.productsMinNarrow,
          );
          _work.geometry = geometry;
          return Obx(() {
            final layout = _work.effective;
            final target = geometry.widthsFor(layout);
            final changed = _drawn != null && _drawn != layout;
            _drawn = layout;
            return TweenAnimationBuilder<PanelWidths>(
              tween: _WidthsTween(end: target),
              duration: Duration(
                milliseconds: animate && changed ? AppMotion.buttonMs : 0,
              ),
              curve: Curves.easeOut,
              builder: (context, w, _) => _WorkRow(
                widths: w,
                target: target,
                layout: layout,
                geometry: geometry,
              ),
            );
          });
        },
      ),
    );
  }
}

class _WidthsTween extends Tween<PanelWidths> {
  _WidthsTween({required PanelWidths super.end});

  @override
  PanelWidths lerp(double t) => PanelWidths.lerp(begin ?? end!, end!, t);
}

class _WorkRow extends StatelessWidget {
  const _WorkRow({
    required this.widths,
    required this.target,
    required this.layout,
    required this.geometry,
  });

  /// The widths of this frame; [target] is where they are heading (a panel
  /// is live from the first frame of its opening).
  final PanelWidths widths;
  final PanelWidths target;

  /// The layout those widths belong to.
  final PanelLayout layout;
  final PanelGeometry geometry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _Pane(order: 0, child: ProductsEdgeControl()),
        const SizedBox(width: AppSpacing.s8),
        _Slot(
          key: const ValueKey<String>('pos-slot-products'),
          width: widths.products,
          layoutWidth: math.max(
            widths.products,
            layout.products == ProductsStep.wide
                ? AppDensitySizes.productsLayoutWide
                : geometry.productsMinNarrow,
          ),
          shown: target.products > 0,
          alignment: Alignment.centerLeft,
          order: 1,
          child: const CatalogPanel(),
        ),
        SizedBox(width: widths.productsGap),
        _Slot(
          key: const ValueKey<String>('pos-slot-cart'),
          width: widths.cart,
          layoutWidth: math.max(widths.cart, geometry.cartMinNarrow),
          shown: target.cart > 0,
          alignment: Alignment.centerLeft,
          order: 2,
          child: const DesktopCartColumn(),
        ),
        SizedBox(width: widths.cartGap),
        _Slot(
          key: const ValueKey<String>('pos-slot-billing'),
          width: widths.billing,
          layoutWidth: geometry.billingWidth,
          shown: target.billing > 0,
          alignment: Alignment.centerRight,
          order: 3,
          child: const BillSummaryFrame(isPos: true, collapsible: true),
        ),
      ],
    );
  }
}

/// One panel: [width] wide on screen, laid out at [layoutWidth] and clipped
/// (a panel narrower than its floor does not reflow into nothing). A panel
/// that is closed and not opening is out of pointer, focus, semantics and
/// tickers, but stays mounted.
class _Slot extends StatelessWidget {
  const _Slot({
    super.key,
    required this.width,
    required this.layoutWidth,
    required this.shown,
    required this.alignment,
    required this.order,
    required this.child,
  });

  final double width;
  final double layoutWidth;
  final bool shown;
  final Alignment alignment;
  final double order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hidden = !shown && width <= 0.5;
    return ClipRect(
      child: SizedBox(
        width: width,
        child: OverflowBox(
          alignment: alignment,
          minWidth: layoutWidth,
          maxWidth: layoutWidth,
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
