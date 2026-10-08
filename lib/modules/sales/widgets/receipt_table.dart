import 'package:flutter/material.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/qty_formatter.dart';
import '../models/receipt_document.dart';

/// `.receipt-items.modal-list > table`: Item, Qty and Total columns that scroll
/// inside a box of at most 26 % of the window height and at least 100 px.
/// The extra width is shared by the three columns (auto table layout).
class ReceiptTable extends StatelessWidget {
  const ReceiptTable({required this.doc, super.key});

  final ReceiptDocument doc;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final height = MediaQuery.sizeOf(context).height;
    final cap = height * AppCheckoutSizes.receiptItemsMaxFraction;
    final maxHeight = cap < AppCheckoutSizes.receiptItemsMinHeight
        ? AppCheckoutSizes.receiptItemsMinHeight
        : cap;
    final base = context.text.fluid(
      AppCheckoutSizes.receiptTableFont,
      height: AppLineHeight.base,
    );
    Widget cell(
      String text, {
      required double padY,
      bool right = false,
      TextStyle? style,
      Color? color,
      bool wrap = true,
    }) => Padding(
      padding: EdgeInsets.symmetric(vertical: padY),
      child: Text(
        text,
        textAlign: right ? TextAlign.right : TextAlign.left,
        softWrap: wrap,
        style: (style ?? base).copyWith(color: color ?? c.text),
      ),
    );
    final head = base.copyWith(fontWeight: AppFontWeight.medium.value);
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: AppCheckoutSizes.receiptItemsMinHeight,
        maxHeight: maxHeight,
      ),
      child: SingleChildScrollView(
        child: Table(
          columnWidths: const <int, TableColumnWidth>{
            0: IntrinsicColumnWidth(flex: 1),
            1: IntrinsicColumnWidth(flex: 1),
            2: IntrinsicColumnWidth(flex: 1),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: <TableRow>[
            TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              children: <Widget>[
                cell(
                  s.receiptColItem(),
                  padY: AppCheckoutSizes.receiptThPadY,
                  style: head,
                  color: c.muted,
                ),
                cell(
                  s.receiptColQty(),
                  padY: AppCheckoutSizes.receiptThPadY,
                  style: head,
                  color: c.muted,
                ),
                cell(
                  s.receiptColTotal(),
                  padY: AppCheckoutSizes.receiptThPadY,
                  right: true,
                  style: head,
                  color: c.muted,
                ),
              ],
            ),
            for (final line in doc.lines)
              TableRow(
                children: <Widget>[
                  cell(line.name, padY: AppCheckoutSizes.receiptTdPadY),
                  cell(
                    QtyFormatter.fixed3(line.qty),
                    padY: AppCheckoutSizes.receiptTdPadY,
                    wrap: false,
                  ),
                  cell(
                    MoneyFormatter.format(line.total),
                    padY: AppCheckoutSizes.receiptTdPadY,
                    right: true,
                    wrap: false,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
