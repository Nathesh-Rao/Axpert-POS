import 'package:flutter/material.dart';

import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_bar.dart';

/// Per-page wrapper: top bar, sidebar and the page body (S2.c adds the
/// offline banner and the Bill Summary frame).
class AppShell extends StatelessWidget {
  const AppShell({required this.page, required this.child, super.key});

  final AppPage page;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          const TopBar(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                0,
                context.metrics.layoutGap,
                context.metrics.layoutGap,
                context.metrics.layoutGap,
              ),
              child: Row(
                children: <Widget>[
                  Sidebar(current: page),
                  SizedBox(width: context.metrics.layoutGap),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
