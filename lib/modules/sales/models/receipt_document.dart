import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/qty.dart';

/// One item row of a receipt: name, quantity and the line total.
class ReceiptLine {
  const ReceiptLine({
    required this.name,
    required this.qty,
    required this.total,
  });

  final String name;
  final Qty qty;
  final Money total;
}

/// A receipt as data (what the prototype's receipt shows): values only, no
/// formatting and no arithmetic. The view and a future printer format it.
class ReceiptDocument {
  const ReceiptDocument({
    required this.number,
    required this.date,
    required this.store,
    required this.cashier,
    required this.customer,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.points,
    required this.tax,
    required this.total,
    required this.mode,
    required this.change,
  });

  final String number;
  final DateTime date;
  final String store;
  final String cashier;
  final String customer;
  final List<ReceiptLine> lines;
  final Money subtotal;
  final Money discount;
  final Money points;
  final Money tax;
  final Money total;

  /// "Cash", "Card", "Credit" or "Unpaid" (a draft).
  final String mode;
  final Money change;
}
