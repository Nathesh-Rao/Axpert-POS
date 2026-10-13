import '../../../core/constants/app_strings.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/tax_split.dart';
import '../../../features/session/domain/entities/session_entities.dart';
import '../../pos/models/cart_line.dart';
import '../../pos/models/line_math.dart';
import '../models/receipt_document.dart';
import '../models/sale.dart';

/// Builds a [ReceiptDocument] from a stored [Sale]. Nothing is calculated
/// here: the totals, change and mode are the sale's own, and each line total
/// is the prototype's `lineTotal` ([LineMath], rounded once for display).
abstract final class ReceiptBuilder {
  /// [store] adds the store row's address, phone and receipt texts. The cashier
  /// is the one who made the sale (empty for sales saved before sessions).
  static ReceiptDocument fromSale(
    Sale sale, {
    StoreInfo? store,
    TaxRegimeInfo? regime,
  }) => ReceiptDocument(
    number: sale.number,
    date: DateTime.parse(sale.date).toLocal(),
    store: sale.store,
    cashier: sale.cashier ?? '',
    address: store?.address ?? '',
    phone: store?.phone ?? '',
    taxId: store?.taxId ?? '',
    header: store?.receiptHeader ?? '',
    footer: store?.receiptFooter ?? '',
    customer: sale.customer,
    lines: <ReceiptLine>[
      for (final line in sale.cart.lines)
        ReceiptLine(
          name: line.product.name,
          qty: line.qty,
          total: LineMath.lineTotal(line),
          note: _note(line),
        ),
    ],
    subtotal: sale.totals.subtotal,
    discount: sale.totals.discount,
    points: sale.totals.points,
    tax: sale.totals.tax,
    taxLabel: regime?.label ?? '',
    taxParts: TaxSplit.parts(sale.totals.tax, regime?.splitParts ?? const []),
    total: sale.totals.total,
    mode: sale.mode,
    change: sale.change,
  );

  static String? _note(CartLine line) {
    final offer = line.offer;
    if (offer == null) return null;
    final s = AppStrings.current;
    if (offer.isGift) return s.giftFreeLabel(offer.name);
    return s.offerSaved(
      offer.name,
      MoneyFormatter.format(Money(offer.savingMinor, line.price.currency)),
    );
  }
}
