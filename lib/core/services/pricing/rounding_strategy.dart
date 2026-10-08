import 'rational.dart';

/// The places where a total is rounded to minor units.
enum RoundingPoint { value, subtotal, discount, tax, points, total }

/// Swappable rounding: turns an exact amount in minor units into an integer.
abstract class RoundingStrategy {
  const RoundingStrategy();

  int round(Rational minorUnits, RoundingPoint point);
}
