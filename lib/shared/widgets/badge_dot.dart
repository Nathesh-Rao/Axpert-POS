import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_sizes.dart';
import '../../core/theme/tokens/app_typography.dart';

/// Round notification badge (13 px, 2 px ring in the page background).
class BadgeDot extends StatelessWidget {
  const BadgeDot(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: AppSizes.notificationDot,
      height: AppSizes.notificationDot,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.notificationDot,
        border: Border.all(color: c.background, width: 2),
      ),
      child: Text(
        label,
        style: context.text
            .of(AppFontSize.s9)
            .copyWith(color: c.white, height: 1),
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
      ),
    );
  }
}
