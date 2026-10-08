import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';

/// `kbd` chip: secondary background, muted text, 4 px radius.
class KbdChip extends StatelessWidget {
  const KbdChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.circular(AppRadii.r4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s6,
          vertical: AppSpacing.s4,
        ),
        child: Text(
          label,
          style: context.text.of(AppFontSize.s14).copyWith(color: c.muted),
        ),
      ),
    );
  }
}
