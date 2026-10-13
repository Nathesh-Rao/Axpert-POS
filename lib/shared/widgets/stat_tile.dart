import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_typography.dart';
import 'css_gradient.dart';

class StatTile extends StatelessWidget {
  const StatTile({
    required this.iconColor,
    required this.iconSize,
    required this.label,
    required this.value,
    required this.valueFontSize,
    required this.padY,
    required this.padX,
    required this.gap,
    this.icon,
    this.iconText,
    this.showIcon = true,
    this.vertical = false,
    super.key,
  }) : assert(icon != null || iconText != null);

  final IconData? icon;
  final String? iconText;
  final Color iconColor;
  final double iconSize;
  final String label;
  final String value;
  final double valueFontSize;
  final double padY;
  final double padX;
  final double gap;
  final bool showIcon;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;

    final glyph = icon != null
        ? Icon(icon, size: iconSize, color: iconColor)
        : Text(
            iconText!.trim(),
            maxLines: 1,
            softWrap: false,
            style: text
                .of(AppFontSize.s16, weight: AppFontWeight.bold)
                .copyWith(fontSize: iconSize, color: iconColor, height: 1),
          );

    return CssGradientBox(
      angleDeg: 130,
      colors: <Color>[c.secondary, c.background],
      borderRadius: BorderRadius.circular(AppRadii.r8),
      padding: EdgeInsets.symmetric(vertical: padY, horizontal: padX),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: label on the left, icon on the right.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text
                      .of(AppFontSize.s12, height: AppLineHeight.base)
                      .copyWith(color: c.muted),
                ),
              ),
              if (showIcon) ...[
                const SizedBox(width: 8),
                Container(
                  width: iconSize + 16,
                  height: iconSize + 16,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.background,
                    borderRadius: BorderRadius.circular(AppRadii.r8),
                  ),
                  child: glyph,
                ),
              ],
            ],
          ),

          SizedBox(height: gap),

          // Value: always anchored to the bottom of the content.
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
    );
  }
}
