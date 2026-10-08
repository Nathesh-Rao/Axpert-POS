import 'decimal_parser.dart';

/// Percentage or rate in integer basis points: 12.5 % is `Bp(1250)`.
class Bp implements Comparable<Bp> {
  const Bp(this.value);

  /// Parses a percent such as "18" or "12.5" (half-up beyond 2 decimals).
  factory Bp.parsePercent(String text) =>
      Bp(DecimalParser.parseScaled(text, 2));

  static const Bp zero = Bp(0);
  static const Bp full = Bp(10000);

  final int value;

  Bp clamp(Bp lo, Bp hi) => Bp(value.clamp(lo.value, hi.value));

  @override
  int compareTo(Bp other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) => other is Bp && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '${value}bp';
}
