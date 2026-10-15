import '../../../core/services/pricing/money.dart';
import '../models/line_key.dart';
import '../../../core/services/pricing/pricing_models.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../core/services/pricing/tax_split.dart';
import '../../customers/models/customer.dart';
import '../../sales/models/sale.dart';
import '../models/cart.dart';
import '../../../core/utils/epoch_time.dart';

/// Payment modes written on a sale (prototype `mode`).
abstract final class SaleMode {
  static const String cash = 'Cash';
  static const String card = 'Card';
  static const String credit = 'Credit';
  static const String unpaid = 'Unpaid';
}

sealed class CheckoutResult {
  const CheckoutResult();
}

/// A line wants more than the product's current stock.
class CheckoutStockChanged extends CheckoutResult {
  const CheckoutStockChanged();
}

class CheckoutDone extends CheckoutResult {
  const CheckoutDone({
    required this.sale,
    required this.stockDeltas,
    required this.pointsDeducted,
  });

  final Sale sale;

  /// Product id to whole units to subtract from the stock (a fractional
  /// quantity is rounded up: stock is whole units, KG-106).
  final Map<int, int> stockDeltas;

  /// Whole points to subtract from the customer.
  final int pointsDeducted;
}

/// The prototype's `complete()`: re-validates stock, builds the sale (number
/// `AX` + 6 digits from `sales.length + 1`, KG-008) and reports what to
/// change. Plain Dart: the controller applies the result.
class CheckoutService {
  const CheckoutService();

  CheckoutResult complete({
    required Cart cart,
    required CartTotals totals,
    required Customer customer,
    required Qty Function(int productId) stockOf,
    required int salesCount,
    required String store,
    String? cashier,
    required DateTime now,
    required String mode,
    required Money tendered,
    String? saleId,
    bool allowNegativeStock = false,
    List<TaxPart> taxParts = const <TaxPart>[],
  }) {
    // A store that allows negative stock sells past the recorded stock
    // (the controller warns); otherwise today's rule holds.
    if (!allowNegativeStock) {
      // Base units summed across all lines of a product (DEC-154).
      for (final id in <int>{for (final l in cart.lines) l.product.id}) {
        if (cart.baseQtyOf(id) > stockOf(id)) {
          return const CheckoutStockChanged();
        }
      }
    }
    final zero = Money(0, totals.total.currency);
    final change = mode == SaleMode.cash && tendered > totals.total
        ? tendered - totals.total
        : zero;
    final sale = Sale(
      saleId: saleId,
      cashier: cashier == null || cashier.isEmpty ? null : cashier,
      number: 'AX${(salesCount + 1).toString().padLeft(6, '0')}',
      date: EpochTime.nowIso(now),
      store: store,
      customer: customer.name,
      cart: cart,
      totals: SaleTotals(
        items: totals.items,
        qty: totals.qty,
        value: totals.value,
        subtotal: totals.subtotal,
        discount: totals.discount,
        tax: totals.tax,
        points: totals.points,
        total: totals.total,
      ),
      mode: mode,
      tendered: tendered,
      change: change,
      returned: const <LineKey, Qty>{},
      taxParts: taxParts,
    );
    return CheckoutDone(
      sale: sale,
      stockDeltas: _stockDeltas(cart),
      pointsDeducted: _wholePoints(totals.points),
    );
  }

  /// Whole base units to take off the shelf per product: the base quantity of
  /// all its lines together, rounded up (a packaged line counts its base
  /// units, DEC-154).
  static Map<int, int> _stockDeltas(Cart cart) {
    final milli = <int, int>{};
    for (final line in cart.lines) {
      milli[line.product.id] =
          (milli[line.product.id] ?? 0) + line.baseQty.milli;
    }
    return <int, int>{
      for (final e in milli.entries) e.key: (e.value + 999) ~/ 1000,
    };
  }

  /// Points are whole numbers here (KG-004): a fractional redeemed amount
  /// (points capped by a total with minor units) is rounded half-up.
  static int _wholePoints(Money points) {
    var unit = 1;
    for (var i = 0; i < points.currency.exponent; i++) {
      unit *= 10;
    }
    return (points.minor * 2 + unit) ~/ (unit * 2);
  }
}
