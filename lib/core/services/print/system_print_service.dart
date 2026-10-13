import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:printing/printing.dart';

import '../../../modules/sales/models/receipt_document.dart';
import '../print_service.dart';
import 'receipt_pdf_builder.dart';
import 'receipt_print_model.dart';

/// Prints through the system print dialog: the browser's dialog on the web
/// (a receipt-only PDF, no app chrome), the OS dialog on Windows, macOS,
/// Linux, Android and iOS (the `printing` package).
class SystemPrintService implements PrintService {
  SystemPrintService({ReceiptPdfBuilder? builder})
    : _builder = builder ?? ReceiptPdfBuilder(rootBundle.load);

  final ReceiptPdfBuilder _builder;

  @override
  bool get supported => true;

  @override
  Future<PrintOutcome> printReceipt(
    ReceiptDocument receipt, {
    required int paperMm,
  }) async {
    try {
      final bytes = await _builder.build(
        ReceiptPrintModel.fromDocument(receipt),
        paperMm: paperMm,
      );
      // False when the user closes the dialog; still "sent": nothing failed.
      await Printing.layoutPdf(
        name: receipt.number,
        onLayout: (_) async => bytes,
      );
      return PrintOutcome.sent;
    } on Object catch (error, stackTrace) {
      debugPrint('SystemPrintService failed: $error\n$stackTrace');
      return PrintOutcome.failed;
    }
  }
}
