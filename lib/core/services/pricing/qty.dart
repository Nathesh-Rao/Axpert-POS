import 'decimal_parser.dart';

/// Quantity in integer milli-units (3 decimals): 1.5 is `Qty(1500)`.
class Qty implements Comparable<Qty> {
  const Qty(this.milli);

  factory Qty.parse(String text) => Qty(DecimalParser.parseScaled(text, scale));

  factory Qty.units(int units) => Qty(units * 1000);

  static const int scale = 3;
  static const Qty zero = Qty(0);

  final int milli;

  Qty operator +(Qty o) => Qty(milli + o.milli);
  Qty operator -(Qty o) => Qty(milli - o.milli);

  @override
  int compareTo(Qty other) => milli.compareTo(other.milli);

  bool operator <(Qty o) => milli < o.milli;
  bool operator >(Qty o) => milli > o.milli;
  bool operator <=(Qty o) => milli <= o.milli;
  bool operator >=(Qty o) => milli >= o.milli;

  @override
  bool operator ==(Object other) => other is Qty && other.milli == milli;

  @override
  int get hashCode => milli.hashCode;

  @override
  String toString() => '${milli}m';
}
