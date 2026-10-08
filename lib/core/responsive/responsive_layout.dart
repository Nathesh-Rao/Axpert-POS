import 'package:flutter/widgets.dart';

import 'app_metrics.dart';
import 'app_metrics_scope.dart';

/// Builds [AppMetrics] from the window's logical size and provides them to
/// the subtree. Only a size change rebuilds the dependents.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return AppMetricsScope(metrics: AppMetrics(size), child: child);
  }
}
