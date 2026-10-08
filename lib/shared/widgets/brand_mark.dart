import 'package:flutter/material.dart';

import '../../core/constants/app_strings_x.dart';
import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';

/// `.brand-mark`: the italic Arial "A" with a light offset shadow. The top bar
/// scales it with the window; the signed-out card uses the CSS 63 / 42.
class BrandMark extends StatelessWidget {
  const BrandMark({required this.width, required this.fontSize, super.key});

  final double width;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: width,
      child: Text(
        context.strings.brandMark(),
        textAlign: TextAlign.center,
        style: AppTypography.arial(
          fontSize,
          weight: FontWeight.w900,
          style: FontStyle.italic,
          shadows: <Shadow>[
            Shadow(
              color: c.brandMarkShadow,
              offset: const Offset(AppSpacing.s2, AppSpacing.s2),
            ),
          ],
        ).copyWith(color: c.brandMark),
      ),
    );
  }
}
