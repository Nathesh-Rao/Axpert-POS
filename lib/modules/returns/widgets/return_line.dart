import 'package:flutter/material.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_management_sizes.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/app_input_box.dart';

/// `.return-line`: the product name with "Available to return: N" under it and
/// the quantity box at the right, a border under the row.
class ReturnLine extends StatelessWidget {
  const ReturnLine({
    required this.name,
    required this.available,
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final String name;

  /// The remaining quantity, as the prototype prints the number.
  final String available;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final body = context.text
        .of(AppFontSize.s14, height: AppLineHeight.base)
        .copyWith(color: c.text);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppManagementSizes.returnLinePadY,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(name, style: body),
                  Text(
                    s.returnsAvailable(available),
                    style: context.text
                        .of(AppFontSize.s12, height: AppLineHeight.base)
                        .copyWith(color: c.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            SizedBox(
              width: AppManagementSizes.returnInputWidth,
              child: AppInputBox(
                controller: controller,
                style: body,
                height: AppManagementSizes.returnInputHeight,
                radius: AppRadii.r6,
                fill: c.secondary,
                borderColor: c.border,
                decimal: true,
                padding: const EdgeInsets.all(
                  AppManagementSizes.returnInputPad,
                ),
                semanticLabel: s.returnsQtyLabel(name),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
