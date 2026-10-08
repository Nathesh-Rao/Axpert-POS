import 'basis_points.dart';
import 'money.dart';
import 'qty.dart';
import 'rational.dart';

class LineInput {
  const LineInput({
    required this.qty,
    required this.price,
    required this.taxRate,
    this.discount = Bp.zero,
  });

  final Qty qty;

  /// Unit price (tax-exclusive or tax-inclusive, per the TaxConfig mode).
  final Money price;
  final Bp discount;
  final Bp taxRate;
}

enum BillDiscountType { percent, flat }

class BillDiscount {
  const BillDiscount.none()
    : type = BillDiscountType.percent,
      percent = Bp.zero,
      flat = null;

  const BillDiscount.percent(this.percent)
    : type = BillDiscountType.percent,
      flat = null;

  const BillDiscount.flat(this.flat)
    : type = BillDiscountType.flat,
      percent = Bp.zero;

  final BillDiscountType type;
  final Bp percent;
  final Money? flat;
}

class CartInput {
  const CartInput({
    required this.lines,
    this.billDiscount = const BillDiscount.none(),
    this.pointsToRedeem = 0,
    this.availablePoints = 0,
  });

  final List<LineInput> lines;
  final BillDiscount billDiscount;

  /// Whole points asked for (1 point = 1 whole currency unit); KG-004.
  final int pointsToRedeem;
  final int availablePoints;
}

/// Unrounded results in minor units, kept so rounding stays one swappable step
/// and tests can detect exact ties.
class ExactTotals {
  const ExactTotals({
    required this.value,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.points,
    required this.total,
    required this.lines,
  });

  final Rational value;
  final Rational subtotal;
  final Rational discount;
  final Rational tax;
  final Rational points;
  final Rational total;
  final List<LineBreakdown> lines;
}

/// Per-line amounts in minor units, unrounded.
class LineBreakdown {
  const LineBreakdown({
    required this.gross,
    required this.net,
    required this.tax,
  });

  /// qty x price.
  final Rational gross;

  /// After the line discount (`lineTotal` in the prototype).
  final Rational net;

  /// Tax attributed to this line after the bill discount.
  final Rational tax;
}

class CartTotals {
  const CartTotals({
    required this.items,
    required this.qty,
    required this.value,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.points,
    required this.total,
    required this.exact,
  });

  final int items;
  final Qty qty;
  final Money value;
  final Money subtotal;
  final Money discount;
  final Money tax;
  final Money points;
  final Money total;
  final ExactTotals exact;
}
