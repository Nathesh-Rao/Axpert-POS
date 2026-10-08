import '../../modules/sales/models/receipt_document.dart';

/// Sending a receipt by email or WhatsApp (a message gateway, later). The
/// prototype only shows a demo toast; here the call goes through this
/// interface and the mock records it.
abstract interface class ReceiptShareService {
  Future<void> sendEmail(ReceiptDocument receipt);

  Future<void> sendWhatsApp(ReceiptDocument receipt);
}

class RecordingReceiptShareService implements ReceiptShareService {
  final List<ReceiptDocument> emailed = <ReceiptDocument>[];
  final List<ReceiptDocument> whatsApped = <ReceiptDocument>[];

  @override
  Future<void> sendEmail(ReceiptDocument receipt) async {
    emailed.add(receipt);
  }

  @override
  Future<void> sendWhatsApp(ReceiptDocument receipt) async {
    whatsApped.add(receipt);
  }
}
