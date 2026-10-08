import 'package:flutter/material.dart';

import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_management_sizes.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/css_gradient.dart';

/// `.bar-chart > div`: the mode name, a track with a gradient bar
/// [basisPoints] of its width, and the amount at the right.
class ReportBar extends StatelessWidget {
  const ReportBar({
    required this.label,
    required this.basisPoints,
    required this.amount,
    super.key,
  });

  final String label;

  /// Bar width as a share of the track, in basis points.
  final int basisPoints;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = context.text
        .of(AppFontSize.s14, height: AppLineHeight.base)
        .copyWith(color: c.text);
    return Row(
      children: <Widget>[
        SizedBox(
          width: AppManagementSizes.chartLabelWidth,
          child: Text(label, maxLines: 1, style: style),
        ),
        const SizedBox(width: AppManagementSizes.chartGap),
        Expanded(
          child: SizedBox(
            height: AppManagementSizes.chartTrackHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.secondary,
                borderRadius: BorderRadius.circular(AppRadii.r5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.r5),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: basisPoints / 10000,
                    heightFactor: 1,
                    child: CssGradientBox(
                      angleDeg: 90,
                      colors: <Color>[c.chartTop, c.chartBottom],
                      borderRadius: BorderRadius.circular(AppRadii.r5),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppManagementSizes.chartGap),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppManagementSizes.chartValueMinWidth,
          ),
          child: Text(
            amount,
            maxLines: 1,
            textAlign: TextAlign.right,
            style: style.copyWith(fontWeight: AppFontWeight.bold.value),
          ),
        ),
      ],
    );
  }
}
