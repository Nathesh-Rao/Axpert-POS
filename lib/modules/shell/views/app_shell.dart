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
    return Scaffold(
      body: Column(
        children: <Widget>[
          const TopBar(),
          const OfflineBanner(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(0, gap, gap, gap),
              child: Row(
                children: <Widget>[
                  Sidebar(current: page),
                  SizedBox(width: gap),
                  Expanded(child: child),
                  SizedBox(width: gap),
                  BillSummaryFrame(isPos: page == AppPage.pos),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
