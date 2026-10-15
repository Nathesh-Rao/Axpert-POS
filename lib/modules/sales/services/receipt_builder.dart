import '../../../core/constants/app_strings.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/qty_formatter.dart';
import '../../../core/services/packaging/packaging_label.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/tax_components.dart';
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
          unitName: line.packaging?.unitName,
          note: _note(line),
        ),
    ],
    subtotal: sale.totals.subtotal,
    discount: sale.totals.discount,
    points: sale.totals.points,
    tax: sale.totals.tax,
    taxLabel: regime == null
        ? ''
        : (regime.taxName.isEmpty
              ? AppStrings.current.receiptTaxGeneric()
              : regime.taxName),
    taxParts: _taxParts(sale, regime),
    total: sale.totals.total,
    mode: sale.mode,
    change: sale.change,
  );

  /// The lines saved with the sale; for an older sale the split of the current
  /// setup (KG-216). One line is shown as the tax row alone.
  static List<TaxPart> _taxParts(Sale sale, TaxRegimeInfo? regime) {
    if (sale.taxParts.isNotEmpty) return sale.taxParts;
    if (regime == null) return const <TaxPart>[];
    final parts = regime.partsOf(sale.totals.tax, const <TaxLineShare>[]);
    return parts.length >= 2 ? parts : const <TaxPart>[];
  }

  /// Under the item: for a packaged line "1 Carton of 24 @ 240.00" (the unit,
  /// its size and the package price), then the offer text, one per line.
  static String? _note(CartLine line) {
    final s = AppStrings.current;
    final pack = line.packaging;
    final offer = line.offer;
    final lines = <String>[
      if (pack != null)
        s.receiptPackLine(
          PackagingLabel.sized(
            pack.unitName,
            QtyFormatter.compact(Qty(pack.quantityBaseMilli)),
          ),
          MoneyFormatter.format(line.price),
        ),
      if (offer != null)
        offer.isGift
            ? s.giftFreeLabel(offer.name)
            : s.offerSaved(
                offer.name,
                MoneyFormatter.format(
                  Money(offer.savingMinor, line.price.currency),
                ),
              ),
    ];
    return lines.isEmpty ? null : lines.join('\n');
  }
}
