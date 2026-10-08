import 'package:flutter/material.dart';

import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_shadows.dart';

/// `.summary-card`: card background, 1 px border, 14 px radius, soft shadow.
class SummaryCard extends StatelessWidget {
  const SummaryCard({required this.padding, required this.child, super.key});

  final double padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(AppRadii.r14),
        border: Border.all(color: c.border, width: AppCheckoutSizes.cardBorder),
        boxShadow: AppShadows.summaryCard.boxShadows,
      ),
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }
}
