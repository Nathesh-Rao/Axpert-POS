import 'rational.dart';
import 'rounding_strategy.dart';

/// Rounds half-up on the exact value at every point, which is where the
/// prototype's `calculate()` rounds. Nothing else is rounded.
class PrototypeRounding extends RoundingStrategy {
  const PrototypeRounding();

  @override
  int round(Rational minorUnits, RoundingPoint point) =>
      minorUnits.roundHalfUp().toInt();
}
