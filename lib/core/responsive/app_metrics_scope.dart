import 'package:flutter/widgets.dart';

import 'app_metrics.dart';

/// Provides [AppMetrics] for the current window size.
class AppMetricsScope extends InheritedWidget {
  const AppMetricsScope({
    required this.metrics,
    required super.child,
    super.key,
  });

  final AppMetrics metrics;

  static AppMetrics of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppMetricsScope>();
    assert(scope != null, 'No AppMetricsScope above this context');
    return scope!.metrics;
  }

  @override
  bool updateShouldNotify(AppMetricsScope oldWidget) =>
      oldWidget.metrics.width != metrics.width ||
      oldWidget.metrics.height != metrics.height;
}

extension AppMetricsX on BuildContext {
  AppMetrics get metrics => AppMetricsScope.of(this);
}
