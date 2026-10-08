import 'package:flutter/material.dart';

import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_management_sizes.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_typography.dart';

/// `.report-stats > div`: the secondary tile with a small label over a bold
/// value; the value scales down where the tile is too narrow (KG-158).
class ReportStat extends StatelessWidget {
  const ReportStat({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.secondary,
        borderRadius: BorderRadius.circular(AppRadii.r9),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppManagementSizes.reportTilePadY,
          horizontal: AppManagementSizes.reportTilePadX,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text
                  .of(AppFontSize.s12, height: AppLineHeight.base)
                  .copyWith(color: c.muted),
            ),
            const SizedBox(height: AppManagementSizes.reportValueMarginTop),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: context.text
                    .fluid(
                      AppManagementSizes.reportValueFont,
                      weight: AppFontWeight.bold,
                      height: AppLineHeight.base,
                    )
                    .copyWith(color: c.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
