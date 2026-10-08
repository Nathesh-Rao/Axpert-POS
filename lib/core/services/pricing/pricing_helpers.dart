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

  /// Refund for returned quantities (prototype formula, App.tsx 625-629): each
  /// line's share of the sale total is `total * (qty * price / saleValue)`,
  /// taken pro rata for the returned quantity. The share uses the line's GROSS
  /// price (line discounts, bill discount and points are not reflected).
  /// Exact, in minor units.
  static Rational refundExact({
    required Money saleTotal,
    required Money saleValue,
    required List<RefundLine> lines,
  }) {
    if (saleValue.isZero) return Rational.zero;
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
    return sum;
  }

  /// [refundExact] rounded half up once to a minor unit.
  static Money refund({
    required Money saleTotal,
    required Money saleValue,
    required List<RefundLine> lines,
  }) => Money(
    refundExact(
      saleTotal: saleTotal,
      saleValue: saleValue,
      lines: lines,
    ).roundHalfUp().toInt(),
    saleTotal.currency,
  );

  /// Forex card (App.tsx 182): `rate > 0 ? total / rate : 0`, exact, in
  /// hundredths of the foreign unit (KG-006). The rate has 3 decimals
  /// (`rateMilli`).
  static Rational forexExactHundredths({
    required Money total,
    required int rateMilli,
  }) {
    if (rateMilli <= 0) return Rational.zero;
    final units = Rational(
      BigInt.from(total.minor),
      BigInt.from(10).pow(total.currency.exponent),
    );
    final rate = Rational(BigInt.from(rateMilli), BigInt.from(1000));
    return units / rate * Rational.fromInt(100);
  }

  /// [forexExactHundredths] rounded half up (`toFixed(2)`).
  static int forexConvertHundredths({
    required Money total,
    required int rateMilli,
  }) => forexExactHundredths(
    total: total,
    rateMilli: rateMilli,
  ).roundHalfUp().toInt();

  /// Percent discount clamped to 0..100 %.
  static BillDiscount clampPercent(Bp percent) =>
      BillDiscount.percent(percent.clamp(Bp.zero, Bp.full));

  /// Flat discount clamped to 0..[max] (the prototype passes the undiscounted
  /// subtotal, KG-005).
  static BillDiscount clampFlat(Money flat, Money max) {
    if (flat.isNegative) return BillDiscount.flat(Money.zero(flat.currency));
    return BillDiscount.flat(flat > max ? max : flat);
  }
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
