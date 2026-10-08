import 'basis_points.dart';
import 'money.dart';
import 'pricing_models.dart';
import 'qty.dart';
import 'rational.dart';

/// Small money helpers that sit next to the pricing service. All exact.
class PricingHelpers {
  const PricingHelpers._();

  /// Cash sales: `max(0, tendered - total)`; other modes give no change.
  static Money changeDue({
    required Money total,
    required Money tendered,
    required bool isCash,
  }) {
    if (!isCash) return Money.zero(total.currency);
    final diff = tendered - total;
    return diff.isNegative ? Money.zero(total.currency) : diff;
  }

  /// Refund for returned quantities (prototype formula): each line's share of
  /// the sale total is `total * (qty * price / saleValue)`, taken pro rata for
  /// the returned quantity. Summed exactly, rounded half-up once for display.
  static Money refund({
    required Money saleTotal,
    required Money saleValue,
    required List<RefundLine> lines,
  }) {
    if (saleValue.isZero) return Money.zero(saleTotal.currency);
    var sum = Rational.zero;
    for (final l in lines) {
      if (l.soldQty.milli == 0) continue;
      final gross =
          Rational(BigInt.from(l.soldQty.milli), BigInt.from(1000)) *
          Rational.fromInt(l.price.minor);
      final share =
          Rational.fromInt(saleTotal.minor) *
          gross /
          Rational.fromInt(saleValue.minor);
      sum +=
          share *
          Rational(BigInt.from(l.returnQty.milli)) /
          Rational(BigInt.from(l.soldQty.milli));
    }
    return Money(sum.roundHalfUp().toInt(), saleTotal.currency);
  }

  /// Forex card: `total / rate` shown with 2 decimals (KG-006). The rate has 3
  /// decimals (`rateMilli`); the result is in hundredths of the foreign unit.
  static int forexConvertHundredths({
    required Money total,
    required int rateMilli,
  }) {
    if (rateMilli <= 0) return 0;
    final units = Rational(
      BigInt.from(total.minor),
      BigInt.from(10).pow(total.currency.exponent),
    );
    final rate = Rational(BigInt.from(rateMilli), BigInt.from(1000));
    return (units / rate * Rational.fromInt(100)).roundHalfUp().toInt();
  }

  /// Whole points allowed: `min(requested, available, whole units payable)`.
  static int clampPoints({
    required int requested,
    required int available,
    required Money payable,
  }) {
    final wholePayable = payable.minor ~/ _unit(payable);
    final capped = [
      requested,
      available,
      wholePayable,
    ].reduce((a, b) => a < b ? a : b);
    return capped < 0 ? 0 : capped;
  }

  /// Percent discount clamped to 0..100 %.
  static BillDiscount clampPercent(Bp percent) =>
      BillDiscount.percent(percent.clamp(Bp.zero, Bp.full));

  /// Flat discount clamped to 0..[max] (the prototype passes the undiscounted
  /// subtotal, KG-005).
  static BillDiscount clampFlat(Money flat, Money max) {
    if (flat.isNegative) return BillDiscount.flat(Money.zero(flat.currency));
    return BillDiscount.flat(flat > max ? max : flat);
  }

  static int _unit(Money m) => BigInt.from(10).pow(m.currency.exponent).toInt();
}

class RefundLine {
  const RefundLine({
    required this.soldQty,
    required this.price,
    required this.returnQty,
  });

  final Qty soldQty;
  final Money price;
  final Qty returnQty;
}
