import '../pricing/rational.dart';

/// Packaging arithmetic, plain Dart (no GetX, no Flutter, no database).
///
/// Quantities are integer milli-units, prices integer minor units, factors
/// are base units per package in milli-units (24000 = 24). Every division is
/// exact (Rational) and rounded half up ONCE, at the end of each method:
///  * [baseQtyMilli]: sold quantity x factor, rounded to a milli-unit;
///  * [packagePriceMinor]: base price x factor, rounded to a minor unit;
///  * [unitOffForPackaging]: base-unit reduction x factor, rounded to a minor
///    unit.
/// Nothing here rounds twice and nothing uses `double`.
class PackagingService {
  const PackagingService();

  static final Rational _thousand = Rational.fromInt(1000);

  /// Base quantity (milli) of [soldMilli] packages of [factorMilli] base
  /// units each: 2 cartons of 24 = `baseQtyMilli(2000, 24000) = 48000`;
  /// 2.5 bags of 25 kg = `62500`.
  int baseQtyMilli(int soldMilli, int factorMilli) {
    _checkFactor(factorMilli);
    return _round(Rational.fromInt(soldMilli) * Rational.fromInt(factorMilli));
  }

  /// Price of one package: the explicit [explicitMinor] when set, else the
  /// derived `basePriceMinor x factor` (a carton of 24 at 10.00 is 240.00).
  int packagePriceMinor({
    required int basePriceMinor,
    required int factorMilli,
    int? explicitMinor,
  }) {
    if (explicitMinor != null) return explicitMinor;
    _checkFactor(factorMilli);
    return _round(
      Rational.fromInt(basePriceMinor) * Rational.fromInt(factorMilli),
    );
  }

  /// A fixed-amount offer reduces the price PER BASE UNIT; per package that
  /// is `unitOff x factor`.
  int unitOffForPackaging(int unitOffMinor, int factorMilli) {
    _checkFactor(factorMilli);
    return _round(
      Rational.fromInt(unitOffMinor) * Rational.fromInt(factorMilli),
    );
  }

  /// Most packages (milli) that fit in [leftBaseMilli] base units. A whole
  /// number of packages ([whole]) is floored to whole packages (no 1.041
  /// cartons); a fractional quantity keeps the milli precision.
  int maxPackagesMilli(
    int leftBaseMilli,
    int factorMilli, {
    required bool whole,
  }) {
    _checkFactor(factorMilli);
    if (leftBaseMilli <= 0) return 0;
    final milli = leftBaseMilli * 1000 ~/ factorMilli;
    return whole ? milli ~/ 1000 * 1000 : milli;
  }

  int _round(Rational numeratorTimesFactor) =>
      (numeratorTimesFactor / _thousand).roundHalfUp().toInt();

  void _checkFactor(int factorMilli) {
    if (factorMilli <= 0) {
      throw ArgumentError.value(factorMilli, 'factorMilli', 'must be > 0');
    }
  }
}
