import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import 'app_pressable.dart';

enum ActionTone { blue, red, purple, orange, neutral }

/// `.action` button: tinted background, icon and label (cart actions).
class ActionButton extends StatelessWidget {
  const ActionButton({
    required this.label,
    required this.icon,
    required this.tone,
    required this.onTap,
    required this.height,
    required this.iconSize,
    required this.fontSize,
    super.key,
  });

  final String label;
  final IconData icon;
  final ActionTone tone;
  final VoidCallback onTap;
  final double height;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (tone) {
      ActionTone.blue => (c.actionBlueBg, c.actionBlueFg),
      ActionTone.red => (c.actionRedBg, c.actionRedFg),
      ActionTone.purple => (c.actionPurpleBg, c.actionPurpleFg),
      ActionTone.orange => (c.actionOrangeBg, c.actionOrangeFg),
      ActionTone.neutral => (c.actionNeutralBg, c.actionNeutralFg),
    };
    return AppPressable(
      onTap: onTap,
      borderRadius: AppRadii.r10,
      builder: (context, hovered) => Container(
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.r10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: iconSize, color: fg),
            const SizedBox(width: AppSpacing.s6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: context.text
                    .fluid(fontSize, height: AppLineHeight.base)
                    .copyWith(color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
