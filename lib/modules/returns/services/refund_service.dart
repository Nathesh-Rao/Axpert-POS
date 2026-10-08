import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/pricing_helpers.dart';
import '../../../core/services/pricing/qty.dart';
import '../../pos/models/cart_line.dart';
import '../../sales/models/sale.dart';
import '../models/refund_request.dart';

/// The Returns page rules (prototype `refund()`, App.tsx 600-662). Plain Dart:
/// integer minor units and milli-quantities; the amount comes from
/// [PricingHelpers.refund], the one implementation of the prototype formula.
abstract final class RefundService {
  /// `sales.find(number.toLowerCase() === text.trim().toLowerCase())`, first
  /// match.
  static Sale? find(Iterable<Sale> sales, String text) {
    final wanted = text.trim().toLowerCase();
    for (final sale in sales) {
      if (sale.number.toLowerCase() == wanted) return sale;
    }
    return null;
  }

  /// The lookup key of a sale number (lowercase), for an index map.
  static String keyOf(String number) => number.toLowerCase();

  /// `line.qty - (sale.returned[id] || 0)`
  static Qty available(Sale sale, CartLine line) =>
      line.qty - (sale.returned[line.product.id] ?? Qty.zero);

  static Map<int, Qty> _positive(Map<int, Qty> typed) => <int, Qty>{
    for (final e in typed.entries)
      if (e.value > Qty.zero) e.key: e.value,
  };

  /// The two checks, in the prototype's order: nothing selected, then a
  /// quantity above what is left to return.
  static RefundCheck check(Sale sale, Map<int, Qty> typed) {
    final entries = _positive(typed);
    if (entries.isEmpty) return RefundCheck.noSelection;
    for (final e in entries.entries) {
      final line = _line(sale, e.key);
      final left = (line?.qty ?? Qty.zero) - (sale.returned[e.key] ?? Qty.zero);
      if (e.value > left) return RefundCheck.exceeds;
    }
    return RefundCheck.ok;
  }

  /// The refund amount: each returned line's share of the sale total by its
  /// gross value (line discount, bill discount and points are not reflected,
  /// KG-165).
  static Money quote(Sale sale, Map<int, Qty> typed) {
    final lines = <RefundLine>[];
    for (final e in _positive(typed).entries) {
      final line = _line(sale, e.key);
      if (line == null) continue;
      lines.add(
        RefundLine(soldQty: line.qty, price: line.price, returnQty: e.value),
      );
    }
    return PricingHelpers.refund(
      saleTotal: sale.totals.total,
      saleValue: sale.totals.value,
      lines: lines,
    );
  }

  /// The sale with `returned[id] += qty` for every selected entry.
  static Sale applyReturned(Sale sale, Map<int, Qty> typed) {
    final entries = _positive(typed);
    return sale.copyWith(
      returned: <int, Qty>{
        ...sale.returned,
        for (final e in entries.entries)
          e.key: (sale.returned[e.key] ?? Qty.zero) + e.value,
      },
    );
  }

  /// Whole units to put back on the shelf: stock is whole units, so a
  /// fractional quantity rounds up as it does when it is sold (KG-106).
  static Map<int, int> restockUnits(Map<int, Qty> typed) => <int, int>{
    for (final e in _positive(typed).entries)
      e.key: (e.value.milli + 999) ~/ 1000,
  };

  static CartLine? _line(Sale sale, int productId) {
    for (final line in sale.cart.lines) {
      if (line.product.id == productId) return line;
    }
    return null;
  }
}
