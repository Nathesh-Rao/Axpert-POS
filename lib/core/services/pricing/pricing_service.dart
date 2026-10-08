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
        throw UnimplementedError('Inclusive mode arrives in S1.c');
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

  ExactTotals _exclusive(CartInput cart) {
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
    final billDiscount = Rational.min(subtotal, requested);
    final ratio = subtotal.isZero
        ? Rational.zero
        : (subtotal - billDiscount) / subtotal;
    var tax = Rational.zero;
    final lines = <LineBreakdown>[];
    for (var i = 0; i < cart.lines.length; i++) {
      final t = net[i] * ratio * _bp(cart.lines[i].taxRate);
      tax += t;
      lines.add(LineBreakdown(gross: gross[i], net: net[i], tax: t));
    }
    final payable = subtotal - billDiscount + tax;
    final points = Rational.min(
      Rational.min(
        _wholeUnits(cart.pointsToRedeem),
        _wholeUnits(cart.availablePoints),
      ),
      payable,
    );
    return ExactTotals(
      value: value,
      subtotal: value,
      discount: value - subtotal + billDiscount,
      tax: tax,
      points: points,
      total: Rational.max(Rational.zero, payable - points),
      lines: lines,
    );
  }
}
