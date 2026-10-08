import '../../pos/models/line_math.dart';
import '../models/receipt_document.dart';
import '../models/sale.dart';

/// Builds a [ReceiptDocument] from a stored [Sale]. Nothing is calculated
/// here: the totals, change and mode are the sale's own, and each line total
/// is the prototype's `lineTotal` ([LineMath], rounded once for display).
abstract final class ReceiptBuilder {
  /// The prototype prints a fixed cashier (`MGTCASH3`, KG-137).
  static const String cashier = 'MGTCASH3';

  static ReceiptDocument fromSale(Sale sale) => ReceiptDocument(
    number: sale.number,
    date: DateTime.parse(sale.date).toLocal(),
    store: sale.store,
    cashier: cashier,
    customer: sale.customer,
    lines: <ReceiptLine>[
      for (final line in sale.cart.lines)
        ReceiptLine(
          name: line.product.name,
          qty: line.qty,
          total: LineMath.lineTotal(line),
        ),
    ],
    subtotal: sale.totals.subtotal,
    discount: sale.totals.discount,
    points: sale.totals.points,
    tax: sale.totals.tax,
    total: sale.totals.total,
    mode: sale.mode,
    change: sale.change,
  );
}
