/// Exact fraction on BigInt. All pricing math runs on this so results are
/// identical on the VM and on web, where Dart ints are JS numbers.
class Rational implements Comparable<Rational> {
  factory Rational(BigInt numerator, [BigInt? denominator]) {
    var n = numerator;
    var d = denominator ?? BigInt.one;
    if (d == BigInt.zero) throw ArgumentError('Zero denominator');
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    final g = n.gcd(d);
    if (g > BigInt.one) {
      n = n ~/ g;
      d = d ~/ g;
    }
    return Rational._(n, d);
  }

  factory Rational.fromInt(int value) => Rational._(BigInt.from(value), _one);

  const Rational._(this.numerator, this.denominator);

  static final BigInt _one = BigInt.one;
  static final Rational zero = Rational._(BigInt.zero, _one);
  static final Rational one = Rational._(_one, _one);

  final BigInt numerator;
  final BigInt denominator;

  bool get isZero => numerator == BigInt.zero;
  bool get isNegative => numerator.isNegative;

  Rational operator +(Rational o) => Rational(
    numerator * o.denominator + o.numerator * denominator,
    denominator * o.denominator,
  );

  Rational operator -(Rational o) => Rational(
    numerator * o.denominator - o.numerator * denominator,
    denominator * o.denominator,
  );

  Rational operator *(Rational o) =>
      Rational(numerator * o.numerator, denominator * o.denominator);

  Rational operator /(Rational o) {
    if (o.isZero) throw ArgumentError('Division by zero');
    return Rational(numerator * o.denominator, denominator * o.numerator);
  }

  Rational operator -() => Rational._(-numerator, denominator);

  @override
  int compareTo(Rational other) =>
      (numerator * other.denominator).compareTo(other.numerator * denominator);

  bool operator <(Rational o) => compareTo(o) < 0;
  bool operator <=(Rational o) => compareTo(o) <= 0;
  bool operator >(Rational o) => compareTo(o) > 0;
  bool operator >=(Rational o) => compareTo(o) >= 0;

  static Rational min(Rational a, Rational b) => a <= b ? a : b;
  static Rational max(Rational a, Rational b) => a >= b ? a : b;

  /// Largest integer not above this value.
  BigInt floor() => (numerator - numerator % denominator) ~/ denominator;

  /// Integer part toward zero.
  BigInt truncate() => numerator ~/ denominator;

  /// `floor(x + 1/2)`: ties go up (toward +infinity), like `Math.round`.
  BigInt roundHalfUp() => Rational(
    numerator * BigInt.two + denominator,
    denominator * BigInt.two,
  ).floor();

  /// True when the value sits exactly halfway between two integers.
  bool get isTie => denominator == BigInt.two;

  @override
  bool operator ==(Object other) =>
      other is Rational &&
      numerator == other.numerator &&
      denominator == other.denominator;

  @override
  int get hashCode => Object.hash(numerator, denominator);

  @override
  String toString() => '$numerator/$denominator';
}
