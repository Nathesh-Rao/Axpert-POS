import 'package:flutter/material.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/dashed_divider.dart';
import '../models/receipt_document.dart';

/// `.receipt-totals`: Subtotal, Discount, Reward Points, GST, the large Total,
/// Payment and Change.
class ReceiptTotals extends StatelessWidget {
  const ReceiptTotals({required this.doc, super.key});

  final ReceiptDocument doc;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    TextStyle style(double size) => context.text
        .fluid(size, height: AppCheckoutSizes.receiptRowLineHeight)
        .copyWith(color: c.text);
    Widget row(
      String label,
      String value, {
      double size = AppCheckoutSizes.receiptRowFont,
      double padY = AppCheckoutSizes.receiptRowPadY,
    }) => Padding(
      padding: EdgeInsets.symmetric(vertical: padY),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(child: Text(label, style: style(size))),
          const SizedBox(width: AppCheckoutSizes.receiptActionsGap),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                softWrap: false,
                style: style(
                  size,
                ).copyWith(fontWeight: AppFontWeight.bold.value),
              ),
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(
        top: AppCheckoutSizes.receiptTotalsMarginTop,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DashedDivider(color: c.border),
          const SizedBox(height: AppCheckoutSizes.receiptTotalsPadTop),
          row(s.receiptSubtotal(), MoneyFormatter.format(doc.subtotal)),
          row(s.receiptDiscount(), MoneyFormatter.format(doc.discount)),
          row(s.receiptPoints(), MoneyFormatter.format(doc.points)),
          row(s.receiptTax(), MoneyFormatter.format(doc.tax)),
          Container(
            margin: const EdgeInsets.only(
              top: AppCheckoutSizes.receiptGrandMarginTop,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.border)),
            ),
            child: row(
              s.receiptTotal(),
              MoneyFormatter.format(doc.total),
              size: AppCheckoutSizes.receiptGrandFont,
              padY: AppCheckoutSizes.receiptGrandPadY,
            ),
          ),
          row(s.receiptPayment(), doc.mode),
          row(s.receiptChange(), MoneyFormatter.format(doc.change)),
        ],
      ),
    );
  }
}
