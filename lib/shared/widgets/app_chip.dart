import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_spacing.dart';
import '../../core/theme/tokens/app_typography.dart';
import 'app_pressable.dart';
import 'css_gradient.dart';

/// Filter chip (`.categories button`, `.subcategories button`): secondary
/// background, radius 7, 1.5 line height. Selected: [selectedGradient] (135deg)
/// or [selectedBackground], text in [selectedForeground].
class AppChip extends StatelessWidget {
  const AppChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.padding,
    required this.fontSize,
    required this.selectedForeground,
    this.selectedBackground,
    this.selectedGradient,
    this.leading,
    this.expand = false,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final EdgeInsets padding;
  final double fontSize;
  final Color selectedForeground;
  final Color? selectedBackground;
  final List<Color>? selectedGradient;

  /// Icon before the label; receives the text color of the current state.
  final Widget Function(Color foreground)? leading;

  /// Fill the width the parent gives (`flex:1` chips) instead of the text width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final foreground = selected ? selectedForeground : c.text;
    final style = context.text
        .fluid(fontSize, height: AppLineHeight.base)
        .copyWith(color: foreground);
    final content = Padding(
      padding: padding,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!(foreground),
            const SizedBox(width: AppSpacing.s7),
          ],
          Text(label, style: style, maxLines: 1, softWrap: false),
        ],
      ),
    );
    final radius = BorderRadius.circular(AppRadii.r7);
    return AppPressable(
      onTap: onTap,
      borderRadius: AppRadii.r7,
      builder: (context, hovered) {
        if (selected && selectedGradient != null) {
          return CssGradientBox(
            angleDeg: 135,
            colors: selectedGradient!,
            borderRadius: radius,
            child: content,
          );
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? selectedBackground : c.secondary,
            borderRadius: radius,
          ),
          child: content,
        );
      },
    );
  }
}
