import '../../../modules/sales/models/receipt_document.dart';
import '../../constants/app_strings.dart';
import '../../utils/date_format.dart';
import '../../utils/money_formatter.dart';
import '../../utils/qty_formatter.dart';

/// How big a printed text row is drawn.
enum PrintSize { small, normal, large }

/// One row of the printed receipt. Pure data: the PDF builder (and the test
/// preview) decide fonts and widths, this decides WHAT is printed.
sealed class PrintRow {
  const PrintRow();
}

/// A centered or left-aligned line of text.
class PrintText extends PrintRow {
  const PrintText(
    this.text, {
    this.center = false,
    this.bold = false,
    this.size = PrintSize.normal,
  });

  final String text;
  final bool center;
  final bool bold;
  final PrintSize size;
}

/// Label on the left, value on the right (totals, tax rows).
class PrintColumns extends PrintRow {
  const PrintColumns(
    this.label,
    this.value, {
    this.bold = false,
    this.size = PrintSize.normal,
  });

  final String label;
  final String value;
  final bool bold;
  final PrintSize size;
}

/// An item: name, optional offer note, then quantity and line total.
class PrintItem extends PrintRow {
  const PrintItem({
    required this.name,
    required this.qty,
    required this.total,
    this.note,
  });

  final String name;
  final String qty;
  final String total;
  final String? note;
}

class PrintDivider extends PrintRow {
  const PrintDivider();
}

/// The rows of a receipt, built from a [ReceiptDocument] (which is built from
/// the sale and the store row). Plain Dart: no Flutter, no `pdf`.
class ReceiptPrintModel {
  const ReceiptPrintModel(this.rows);

  /// [AppStrings.current] words, [MoneyFormatter] amounts (integer minor
  /// units, never a double).
  factory ReceiptPrintModel.fromDocument(ReceiptDocument doc) {
    final s = AppStrings.current;
    return ReceiptPrintModel(<PrintRow>[
      PrintText(
        s.receiptBrand(),
        center: true,
        bold: true,
        size: PrintSize.large,
      ),
      PrintText(doc.store, center: true, bold: true),
      for (final line in <String>[
        if (doc.address.isNotEmpty) doc.address,
        if (doc.phone.isNotEmpty) doc.phone,
        if (doc.taxId.isNotEmpty) doc.taxId,
        if (doc.header.isNotEmpty) doc.header,
        s.receiptTagline(),
      ])
        PrintText(line, center: true, size: PrintSize.small),
      const PrintDivider(),
      PrintText(s.receiptBill(doc.number), size: PrintSize.small),
      PrintText(DateFormatter.dateTimeComma(doc.date), size: PrintSize.small),
      PrintText(s.receiptCashier(doc.cashier), size: PrintSize.small),
      PrintText(s.receiptCustomer(doc.customer), size: PrintSize.small),
      const PrintDivider(),
      for (final line in doc.lines)
        PrintItem(
          name: line.name,
          qty: QtyFormatter.fixed3WithUnit(line.qty, line.unitName),
          total: MoneyFormatter.format(line.total),
          note: line.note,
        ),
      const PrintDivider(),
      PrintColumns(s.receiptSubtotal(), MoneyFormatter.format(doc.subtotal)),
      PrintColumns(s.receiptDiscount(), MoneyFormatter.format(doc.discount)),
      PrintColumns(s.receiptPoints(), MoneyFormatter.format(doc.points)),
      if (doc.taxLabel.isNotEmpty) ...<PrintRow>[
        PrintColumns(doc.taxLabel, MoneyFormatter.format(doc.tax)),
        for (final part in doc.taxParts)
          PrintColumns(part.label, MoneyFormatter.format(part.amount)),
      ],
      const PrintDivider(),
      PrintColumns(
        s.receiptTotal(),
        MoneyFormatter.format(doc.total),
        bold: true,
        size: PrintSize.large,
      ),
      PrintColumns(s.receiptPayment(), doc.mode),
      PrintColumns(s.receiptChange(), MoneyFormatter.format(doc.change)),
      const PrintDivider(),
      PrintText(
        doc.footer.isEmpty ? s.receiptThanks() : doc.footer,
        center: true,
      ),
    ]);
  }

  final List<PrintRow> rows;
}
