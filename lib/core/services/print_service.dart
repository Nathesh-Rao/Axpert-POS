import '../../modules/sales/models/receipt_document.dart';

/// What a print request ended in. `sent` means the system print dialog (or the
/// browser's) took the document, not that paper came out.
enum PrintOutcome { sent, unsupported, failed }

/// Receipt printing. The controllers depend on this interface only; the real
/// implementation (`SystemPrintService`, system print dialog on every
/// platform) is chosen by `createPrintService()` with a conditional import.
/// Thermal printers, cash drawers and ESC/POS stay separate interfaces later.
abstract interface class PrintService {
  /// False when this platform cannot print (the caller shows a toast).
  bool get supported;

  /// Prints [receipt] on paper [paperMm] millimetres wide. Never throws.
  Future<PrintOutcome> printReceipt(
    ReceiptDocument receipt, {
    required int paperMm,
  });
}

/// The stand-in for tests: remembers what would have been printed.
class RecordingPrintService implements PrintService {
  RecordingPrintService({this.supported = true, this.outcome});

  @override
  final bool supported;

  /// Forces an outcome (default: sent, or unsupported when not [supported]).
  final PrintOutcome? outcome;

  final List<ReceiptDocument> printed = <ReceiptDocument>[];
  final List<int> paperMm = <int>[];

  @override
  Future<PrintOutcome> printReceipt(
    ReceiptDocument receipt, {
    required int paperMm,
  }) async {
    if (!supported) return PrintOutcome.unsupported;
    printed.add(receipt);
    this.paperMm.add(paperMm);
    return outcome ?? PrintOutcome.sent;
  }
}
