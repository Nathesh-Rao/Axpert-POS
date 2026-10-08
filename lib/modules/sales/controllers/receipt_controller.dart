import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/print_service.dart';
import '../../../core/services/receipt_share_service.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/controllers/toast_controller.dart';
import '../models/receipt_document.dart';
import '../models/sale.dart';
import '../services/receipt_builder.dart';

/// The receipt dialog: the sale handed over as the overlay payload, the
/// Print, Email and WhatsApp buttons (services, demo toasts as in the
/// prototype) and "New Sale", which only closes (the cart was cleared when the
/// payment completed).
class ReceiptController extends GetxController {
  ReceiptController({
    required this.overlay,
    required this.toasts,
    required this.printer,
    required this.sharing,
  });

  final OverlayController overlay;
  final ToastController toasts;
  final PrintService printer;
  final ReceiptShareService sharing;

  AppStrings get _s => AppStrings.current;

  /// The receipt of the open dialog; null when none was handed over.
  ReceiptDocument? get receipt {
    final payload = overlay.payload;
    return payload is Sale ? ReceiptBuilder.fromSale(payload) : null;
  }

  void print() {
    final doc = receipt;
    if (doc != null) printer.printReceipt(doc);
  }

  void email() {
    final doc = receipt;
    if (doc != null) sharing.sendEmail(doc);
    toasts.show(_s.toastReceiptEmail());
  }

  void whatsApp() {
    final doc = receipt;
    if (doc != null) sharing.sendWhatsApp(doc);
    toasts.show(_s.toastReceiptWhatsApp());
  }

  void newSale() => overlay.close();
}
