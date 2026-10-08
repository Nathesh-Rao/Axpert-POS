import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_sizes.dart';
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
    this.stacked = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final ActionTone tone;
  final VoidCallback onTap;
  final double height;
  final double iconSize;
  final double fontSize;

  /// Width <= 1700: the icon sits above the label.
  final bool stacked;

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
        child: _content(context, fg),
      ),
    );
  }

  Widget _content(BuildContext context, Color fg) {
    final labelText = Flexible(
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: context.text
            .fluid(fontSize, height: AppLineHeight.base)
            .copyWith(color: fg),
      ),
    );
    final iconWidget = Icon(icon, size: iconSize, color: fg);
    // Stacked: the content (about 40 px) may be taller than the padded box,
    // which CSS lets overflow unseen; here it is simply centered.
    return stacked
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              iconWidget,
              const SizedBox(height: AppSizes.cartActionStackedIconGap),
              labelText,
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              iconWidget,
              const SizedBox(width: AppSpacing.s6),
              labelText,
            ],
          );
  }
}
