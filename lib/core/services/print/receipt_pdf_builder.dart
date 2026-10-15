import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'receipt_print_model.dart';

/// Reads a bundled font file (`rootBundle.load` in the app, the file system in
/// tests).
typedef PdfFontLoader = Future<ByteData> Function(String asset);

/// Draws a [ReceiptPrintModel] as a one-page PDF on roll paper: the page is
/// `paperMm` wide and as tall as its content. Fonts are bundled
/// (Roboto Condensed has the rupee and euro signs), so printing works offline.
class ReceiptPdfBuilder {
  const ReceiptPdfBuilder(this._loadFont);

  static const String regularAsset = 'assets/fonts/RobotoCondensed-Regular.ttf';
  static const String boldAsset = 'assets/fonts/RobotoCondensed-Bold.ttf';

  /// Page margin in millimetres.
  static const double marginMm = 3;

  final PdfFontLoader _loadFont;

  /// Font size in points of the "normal" size at [paperMm] (narrow rolls print
  /// a little smaller).
  static double baseFont(int paperMm) => paperMm >= 70 ? 9.5 : 8.5;

  static double _factor(PrintSize size) => switch (size) {
    PrintSize.small => 0.88,
    PrintSize.normal => 1,
    PrintSize.large => 1.45,
  };

  Future<Uint8List> build(
    ReceiptPrintModel model, {
    required int paperMm,
  }) async {
    final regular = pw.Font.ttf(await _loadFont(regularAsset));
    final bold = pw.Font.ttf(await _loadFont(boldAsset));
    final base = baseFont(paperMm);
    pw.TextStyle style(bool isBold, PrintSize size) => pw.TextStyle(
      font: isBold ? bold : regular,
      fontSize: base * _factor(size),
    );

    pw.Widget rowOf(PrintRow row) => switch (row) {
      PrintText() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1),
        child: pw.SizedBox(
          width: double.infinity,
          child: pw.Text(
            row.text,
            textAlign: row.center ? pw.TextAlign.center : pw.TextAlign.left,
            style: style(row.bold, row.size),
          ),
        ),
      ),
      PrintColumns(wrapLabel: true) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Expanded(
              child: pw.Text(row.label, style: style(row.bold, row.size)),
            ),
            pw.SizedBox(width: 6),
            pw.Text(row.value, style: style(row.bold, row.size)),
          ],
        ),
      ),
      PrintColumns() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Text(row.label, style: style(row.bold, row.size)),
            pw.Text(row.value, style: style(row.bold, row.size)),
          ],
        ),
      ),
      PrintItem() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(row.name, style: style(false, PrintSize.normal)),
            if (row.note != null)
              pw.Text(row.note!, style: style(false, PrintSize.small)),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: <pw.Widget>[
                pw.Text(row.qty, style: style(false, PrintSize.small)),
                pw.Text(row.total, style: style(false, PrintSize.normal)),
              ],
            ),
          ],
        ),
      ),
      PrintDivider() => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Divider(
          height: 1,
          thickness: 0.5,
          borderStyle: pw.BorderStyle.dashed,
        ),
      ),
    };

    final document = pw.Document(title: 'Receipt');
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          paperMm * PdfPageFormat.mm,
          double.infinity,
          marginAll: marginMm * PdfPageFormat.mm,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: <pw.Widget>[for (final row in model.rows) rowOf(row)],
        ),
      ),
    );
    return document.save();
  }
}
