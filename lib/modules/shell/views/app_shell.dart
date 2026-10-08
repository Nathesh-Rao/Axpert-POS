import 'package:flutter/material.dart';

import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../widgets/bill_summary_frame.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';

/// Per-page wrapper (DEC-041): top bar, offline banner, sidebar, the page and
/// the Bill Summary frame on every page. Controllers are permanent, so the
/// search text/focus and the cart survive navigation.
class AppShell extends StatelessWidget {
  const AppShell({required this.page, required this.child, super.key});

  final AppPage page;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final gap = context.metrics.layoutGap;
    // Tab visits the regions in the prototype's DOM order (top bar, sidebar,
    // page, Bill Summary) instead of the default top-to-bottom, left-to-right
    // sweep, which would interleave sidebar buttons and page controls.
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Scaffold(
        body: Column(
          children: <Widget>[
            const _Region(order: 0, child: TopBar()),
            const OfflineBanner(),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, gap, gap, gap),
                child: Row(
                  children: <Widget>[
                    _Region(order: 1, child: Sidebar(current: page)),
                    SizedBox(width: gap),
                    Expanded(child: _Region(order: 2, child: child)),
                    SizedBox(width: gap),
                    _Region(
                      order: 3,
                      child: BillSummaryFrame(isPos: page == AppPage.pos),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One tab-order region: its position in the page and its own reading order
/// inside.
class _Region extends StatelessWidget {
  const _Region({required this.order, required this.child});

  final double order;
  final Widget child;

  @override
  Widget build(BuildContext context) => FocusTraversalOrder(
    order: NumericFocusOrder(order),
    child: FocusTraversalGroup(child: child),
  );
}
