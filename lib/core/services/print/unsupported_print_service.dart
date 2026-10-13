import '../../../modules/sales/models/receipt_document.dart';
import '../print_service.dart';

/// Used where the platform cannot print: reports `unsupported`, never throws.
class UnsupportedPrintService implements PrintService {
  const UnsupportedPrintService();

  @override
  bool get supported => false;

  @override
  Future<PrintOutcome> printReceipt(
    ReceiptDocument receipt, {
    required int paperMm,
  }) async => PrintOutcome.unsupported;
}
