import '../../modules/sales/models/receipt_document.dart';

/// Receipt printing (hardware or the browser's print dialog, later). Only the
/// interface exists in Phase A; the app calls it and the mock records it.
/// A real printer is one new implementation chosen with a conditional import
/// (web: `window.print()`, Windows: the print spooler); no UI changes.
abstract interface class PrintService {
  Future<void> printReceipt(ReceiptDocument receipt);
}

/// The stand-in used now: remembers what would have been printed (tests).
class RecordingPrintService implements PrintService {
  final List<ReceiptDocument> printed = <ReceiptDocument>[];

  @override
  Future<void> printReceipt(ReceiptDocument receipt) async {
    printed.add(receipt);
  }
}
