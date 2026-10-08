import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_checkout_sizes.dart';
import '../../core/theme/tokens/app_typography.dart';

/// `.shift-summary p` / `.profile-info p`: a label at the left and a bold
/// value at the right, 13 px above and below, a border under the row.
class ModalInfoRow extends StatelessWidget {
  const ModalInfoRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = context.text
        .of(AppFontSize.s14, height: AppLineHeight.base)
        .copyWith(color: c.text);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppCheckoutSizes.shortcutRowPadY,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(child: Text(label, style: style)),
            const SizedBox(width: AppCheckoutSizes.receiptActionsGap),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: style.copyWith(fontWeight: AppFontWeight.bold.value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
