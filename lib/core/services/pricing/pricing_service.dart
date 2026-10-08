import 'basis_points.dart';
import 'currency.dart';
import 'money.dart';
import 'pricing_models.dart';
import 'prototype_rounding.dart';
import 'qty.dart';
import 'rational.dart';
import 'rounding_strategy.dart';
import 'tax_config.dart';

/// Tax, discount, points and total logic. Plain Dart, exact rationals, and
/// rounding only through the [RoundingStrategy].
class PricingService {
  const PricingService({
    this.config = TaxConfig.india,
    this.rounding = const PrototypeRounding(),
  });

  final TaxConfig config;
  final RoundingStrategy rounding;

  static final Rational _thousand = Rational.fromInt(1000);
  static final Rational _tenThousand = Rational.fromInt(10000);

  CartTotals calculate(CartInput cart) {
    final exact = calculateExact(cart);
    final currency = config.currency;
    Money money(Rational minor, RoundingPoint point) =>
        Money(rounding.round(minor, point), currency);
    var qty = Qty.zero;
    for (final line in cart.lines) {
      qty += line.qty;
    }
    return CartTotals(
      items: cart.lines.length,
      qty: qty,
      value: money(exact.value, RoundingPoint.value),
      subtotal: money(exact.subtotal, RoundingPoint.subtotal),
      discount: money(exact.discount, RoundingPoint.discount),
      tax: money(exact.tax, RoundingPoint.tax),
      points: money(exact.points, RoundingPoint.points),
      total: money(exact.total, RoundingPoint.total),
      exact: exact,
    );
  }

  ExactTotals calculateExact(CartInput cart) {
    for (final line in cart.lines) {
      _checkCurrency(line.price.currency);
    }
    final flat = cart.billDiscount.flat;
    if (flat != null) _checkCurrency(flat.currency);
    switch (config.mode) {
      case TaxMode.exclusive:
        return _exclusive(cart);
      case TaxMode.inclusive:
        return _inclusive(cart);
    }
  }

  void _checkCurrency(Currency c) {
    if (c != config.currency) throw CurrencyMismatch(config.currency, c);
  }

  Rational _qty(Qty q) => Rational(BigInt.from(q.milli)) / _thousand;

  Rational _bp(Bp b) => Rational(BigInt.from(b.value)) / _tenThousand;

  Rational _wholeUnits(int units) => Rational(
    BigInt.from(units) * BigInt.from(10).pow(config.currency.exponent),
  );

  _Base _base(CartInput cart) {
    final gross = <Rational>[];
    final net = <Rational>[];
    var value = Rational.zero;
    var subtotal = Rational.zero;
    for (final line in cart.lines) {
      final g = _qty(line.qty) * Rational.fromInt(line.price.minor);
      final n = g * (Rational.one - _bp(line.discount));
      gross.add(g);
      net.add(n);
      value += g;
      subtotal += n;
    }
    final requested = cart.billDiscount.flat != null
        ? Rational.fromInt(cart.billDiscount.flat!.minor)
        : subtotal * _bp(cart.billDiscount.percent);
    return _Base(
      gross: gross,
      net: net,
      value: value,
      subtotal: subtotal,
      billDiscount: Rational.min(subtotal, requested),
    );
  }

  Rational _pointsCap(CartInput cart, Rational payable) => Rational.min(
    Rational.min(
      _wholeUnits(cart.pointsToRedeem),
      _wholeUnits(cart.availablePoints),
    ),
    payable,
  );

  /// Prices exclude tax: tax is added on top of the discounted lines.
  ExactTotals _exclusive(CartInput cart) {
    final b = _base(cart);
    final ratio = b.subtotal.isZero
        ? Rational.zero
        : (b.subtotal - b.billDiscount) / b.subtotal;
    var tax = Rational.zero;
    final lines = <LineBreakdown>[];
    for (var i = 0; i < cart.lines.length; i++) {
      final t = b.net[i] * ratio * _bp(cart.lines[i].taxRate);
      tax += t;
      lines.add(LineBreakdown(gross: b.gross[i], net: b.net[i], tax: t));
    }
    final payable = b.subtotal - b.billDiscount + tax;
    final points = _pointsCap(cart, payable);
    return ExactTotals(
      value: b.value,
      subtotal: b.value,
      discount: b.value - b.subtotal + b.billDiscount,
      tax: tax,
      points: points,
      total: Rational.max(Rational.zero, payable - points),
      lines: lines,
    );
  }

  /// Prices include tax (DEC-022): the bill discount is allocated on gross
  /// line amounts, each line's tax is `gross * r / (100 + r)`, tax is only
  /// informational, and points are capped at the discounted gross.
  ExactTotals _inclusive(CartInput cart) {
    final b = _base(cart);
    final ratio = b.subtotal.isZero
        ? Rational.zero
        : (b.subtotal - b.billDiscount) / b.subtotal;
    var tax = Rational.zero;
    final lines = <LineBreakdown>[];
    for (var i = 0; i < cart.lines.length; i++) {
      final r = _bp(cart.lines[i].taxRate);
      final t = b.net[i] * ratio * r / (Rational.one + r);
      tax += t;
      lines.add(LineBreakdown(gross: b.gross[i], net: b.net[i], tax: t));
    }
    final payable = b.subtotal - b.billDiscount;
    final points = _pointsCap(cart, payable);
    return ExactTotals(
      value: b.value,
      subtotal: b.value,
      discount: b.value - b.subtotal + b.billDiscount,
      tax: tax,
      points: points,
      total: Rational.max(Rational.zero, payable - points),
      lines: lines,
    );
  }
}

class _Base {
  const _Base({
    required this.gross,
    required this.net,
    required this.value,
    required this.subtotal,
    required this.billDiscount,
  });

  final List<Rational> gross;
  final List<Rational> net;
  final Rational value;
  final Rational subtotal;
  final Rational billDiscount;
}
