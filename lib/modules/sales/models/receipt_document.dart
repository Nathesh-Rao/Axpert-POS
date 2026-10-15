import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../core/services/pricing/tax_split.dart';

/// One item row of a receipt: name, quantity and the line total.
class ReceiptLine {
  const ReceiptLine({
    required this.name,
    required this.qty,
    required this.total,
    this.unitName,
    this.note,
  });

  final String name;
  final Qty qty;
  final Money total;

  /// The packaging the line was sold in ("Carton"); null = base unit. [qty]
  /// then counts packages (DEC-154).
  final String? unitName;

  /// Text printed under the item: the pack detail of a packaged line, then the
  /// offer (name and saving, or the free item).
  final String? note;
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
    this.taxLabel = '',
    this.taxParts = const <TaxPart>[],
    this.address = '',
    this.phone = '',
    this.taxId = '',
    this.header = '',
    this.footer = '',
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

  /// Tax name of the store's regime (`GST`, `VAT`); empty = no tax row.
  final String taxLabel;

  /// Split of [tax] (`CGST`, `SGST`); empty = one line.
  final List<TaxPart> taxParts;

  /// "Cash", "Card", "Credit" or "Unpaid" (a draft).
  final String mode;
  final Money change;

  /// Store details from the store row; empty when not set.
  final String address;
  final String phone;
  final String taxId;
  final String header;
  final String footer;
}
