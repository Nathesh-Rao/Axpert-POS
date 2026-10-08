import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_spacing.dart';
import 'app_pressable.dart';

class SegmentedItem {
  const SegmentedItem({
    required this.icon,
    required this.iconSize,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final double iconSize;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;
}

/// Icon segmented control (`.view-toggle`): bordered box, radius 9, padding 2,
/// gap 2, radius-7 buttons; the selected one has the tab background.
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    required this.items,
    required this.buttonWidth,
    required this.buttonHeight,
    super.key,
  });

  final List<SegmentedItem> items;
  final double buttonWidth;
  final double buttonHeight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(AppRadii.r9),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var i = 0; i < items.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: AppSpacing.s2),
              AppPressable(
                tooltip: items[i].tooltip,
                onTap: items[i].onTap,
                borderRadius: AppRadii.r7,
                builder: (context, hovered) => Container(
                  width: buttonWidth,
                  height: buttonHeight,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: items[i].selected ? c.selectedTabBg : null,
                    borderRadius: BorderRadius.circular(AppRadii.r7),
                  ),
                  child: Icon(
                    items[i].icon,
                    size: items[i].iconSize,
                    color: items[i].selected ? c.blue : c.viewToggleFg,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
