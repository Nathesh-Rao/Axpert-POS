import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/pricing_models.dart';
import '../../../core/services/pricing/qty.dart';
import '../../customers/models/customer.dart';
import '../../sales/models/sale.dart';
import '../models/cart.dart';

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
    required DateTime now,
    required String mode,
    required Money tendered,
  }) {
    for (final line in cart.lines) {
      if (line.qty > stockOf(line.product.id)) {
        return const CheckoutStockChanged();
      }
    }
    final zero = Money(0, totals.total.currency);
    final change = mode == SaleMode.cash && tendered > totals.total
        ? tendered - totals.total
        : zero;
    final sale = Sale(
      number: 'AX${(salesCount + 1).toString().padLeft(6, '0')}',
      date: now.toUtc().toIso8601String(),
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
      returned: const <int, Qty>{},
    );
    return CheckoutDone(
      sale: sale,
      stockDeltas: <int, int>{
        for (final line in cart.lines)
          line.product.id: (line.qty.milli + 999) ~/ 1000,
      },
      pointsDeducted: _wholePoints(totals.points),
    );
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
