import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import 'css_gradient.dart';

/// `.stat-tiles > div`: gradient tile (130deg secondary to background) with an
/// icon and a muted label over a bold value.
class StatTile extends StatelessWidget {
  const StatTile({
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.label,
    required this.value,
    required this.valueFontSize,
    required this.padY,
    required this.padX,
    required this.gap,
    this.showIcon = true,
    this.vertical = false,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final String label;
  final String value;
  final double valueFontSize;
  final double padY;
  final double padX;
  final double gap;

  /// False at width <= 1100 (the icon is hidden).
  final bool showIcon;

  /// Width <= 1100: column direction, content left aligned.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    return CssGradientBox(
      angleDeg: 130,
      colors: <Color>[c.secondary, c.background],
      borderRadius: BorderRadius.circular(AppRadii.r8),
      padding: EdgeInsets.symmetric(vertical: padY, horizontal: padX),
      child: Row(
        mainAxisAlignment: vertical
            ? MainAxisAlignment.start
            : MainAxisAlignment.center,
        children: <Widget>[
          if (showIcon) ...<Widget>[
            Icon(icon, size: iconSize, color: iconColor),
            SizedBox(width: gap),
          ],
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: text
                      .of(AppFontSize.s12, height: AppLineHeight.base)
                      .copyWith(color: c.muted),
                ),
                const SizedBox(height: AppSpacing.s5),
                Text(
                  value,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: text
                      .fluid(
                        valueFontSize,
                        weight: AppFontWeight.bold,
                        height: AppLineHeight.base,
                      )
                      .copyWith(color: c.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
