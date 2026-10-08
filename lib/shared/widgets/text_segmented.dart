import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_checkout_sizes.dart';
import '../../core/theme/tokens/app_radii.dart';
import '../../core/theme/tokens/app_shadows.dart';
import '../../core/theme/tokens/app_typography.dart';
import 'app_pressable.dart';

class TextSegment {
  const TextSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
}

/// `.segmented`: secondary background, padding 4, radius 8, gap 4; equal
/// buttons (padding 11, radius 6); the selected one is a card with blue text
/// and a soft shadow.
class TextSegmented extends StatelessWidget {
  const TextSegmented({required this.segments, super.key});

  final List<TextSegment> segments;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = context.text.of(
      AppFontSize.s14,
      weight: AppFontWeight.medium,
      height: AppLineHeight.base,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.circular(AppRadii.r8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppCheckoutSizes.segmentedPad),
        child: Row(
          children: <Widget>[
            for (var i = 0; i < segments.length; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: AppCheckoutSizes.segmentedGap),
              Expanded(
                child: AppPressable(
                  borderRadius: AppRadii.r6,
                  semanticLabel: segments[i].label,
                  onTap: segments[i].onTap,
                  builder: (context, hovered) => Container(
                    padding: const EdgeInsets.all(
                      AppCheckoutSizes.segmentedButtonPad,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: segments[i].selected ? c.card : null,
                      borderRadius: BorderRadius.circular(AppRadii.r6),
                      boxShadow: segments[i].selected
                          ? AppShadows.segmentedSelected.boxShadows
                          : null,
                    ),
                    child: Text(
                      segments[i].label,
                      textAlign: TextAlign.center,
                      style: style.copyWith(
                        color: segments[i].selected ? c.blue : c.text,
                      ),
                    ),
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
