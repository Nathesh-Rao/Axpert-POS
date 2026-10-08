import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_shadows.dart';

/// `.panel`: card background, 14 px radius, soft shadow, no border.
class AppPanel extends StatelessWidget {
  const AppPanel({this.padding = EdgeInsets.zero, this.child, super.key});

  final EdgeInsetsGeometry padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(AppRadii.r14),
        boxShadow: AppShadows.panel.boxShadows,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
