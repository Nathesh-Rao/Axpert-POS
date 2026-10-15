import '../../../core/services/packaging/packaging_service.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/pricing_helpers.dart';
import '../../../core/services/pricing/qty.dart';
import '../../pos/models/cart_line.dart';
import '../../pos/models/line_key.dart';
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
      line.qty - (sale.returned[line.key] ?? Qty.zero);

  static Map<LineKey, Qty> _positive(Map<LineKey, Qty> typed) => <LineKey, Qty>{
    for (final e in typed.entries)
      if (e.value > Qty.zero) e.key: e.value,
  };

  /// The two checks, in the prototype's order: nothing selected, then a
  /// quantity above what is left to return.
  static RefundCheck check(Sale sale, Map<LineKey, Qty> typed) {
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
  static Money quote(Sale sale, Map<LineKey, Qty> typed) {
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
  static Sale applyReturned(Sale sale, Map<LineKey, Qty> typed) {
    final entries = _positive(typed);
    return sale.copyWith(
      returned: <LineKey, Qty>{
        ...sale.returned,
        for (final e in entries.entries)
          e.key: (sale.returned[e.key] ?? Qty.zero) + e.value,
      },
    );
  }

  /// Whole base units to put back on the shelf per product (stock is whole
  /// units, so a fraction rounds up as it does when it is sold, KG-106). A
  /// returned carton puts back its base units (DEC-151); the lines of one
  /// product add up before rounding. Without [sale] every entry counts base
  /// units.
  static Map<int, int> restockUnits(Map<LineKey, Qty> typed, {Sale? sale}) {
    final milli = <int, int>{};
    for (final e in _positive(typed).entries) {
      milli[e.key.productId] =
          (milli[e.key.productId] ?? 0) + baseQty(sale, e.key, e.value).milli;
    }
    return <int, int>{
      for (final e in milli.entries) e.key: (e.value + 999) ~/ 1000,
    };
  }

  /// [qty] of the line [key] in base units: `qty x quantity_base` when the
  /// sale line was sold in a packaging, else [qty].
  static Qty baseQty(Sale? sale, LineKey key, Qty qty) {
    final packaging = sale == null ? null : _line(sale, key)?.packaging;
    if (packaging == null) return qty;
    return Qty(
      const PackagingService().baseQtyMilli(
        qty.milli,
        packaging.quantityBaseMilli,
      ),
    );
  }

  static CartLine? _line(Sale sale, LineKey key) {
    for (final line in sale.cart.lines) {
      if (line.key == key) return line;
    }
    return null;
  }
}
