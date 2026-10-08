import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/prototype_rounding.dart';
import 'package:pos_application/core/services/pricing/rational.dart';
import 'package:pos_application/core/services/pricing/rounding_strategy.dart';

Rational r(int n, int d) => Rational(BigInt.from(n), BigInt.from(d));

void main() {
  test('half-up at ties, zero and negatives', () {
    expect(r(1, 2).roundHalfUp(), BigInt.one);
    expect(r(3, 2).roundHalfUp(), BigInt.two);
    expect(r(-1, 2).roundHalfUp(), BigInt.zero);
    expect(r(-3, 2).roundHalfUp(), BigInt.from(-1));
    expect(r(0, 5).roundHalfUp(), BigInt.zero);
    expect(r(49, 100).roundHalfUp(), BigInt.zero);
    expect(r(-51, 100).roundHalfUp(), BigInt.from(-1));
    expect(r(7, 1).roundHalfUp(), BigInt.from(7));
  });

  test('normalizes and compares exactly', () {
    expect(r(2, 4), r(1, 2));
    expect(r(1, -2), r(-1, 2));
    expect(r(1, 3) + r(1, 6), r(1, 2));
    expect(r(1, 3) * r(3, 1), Rational.one);
    expect(r(1, 2) / r(1, 4), Rational.fromInt(2));
    expect(r(1, 3) < r(1, 2), isTrue);
    expect(Rational.min(r(1, 3), r(1, 2)), r(1, 3));
    expect(r(-7, 2).floor(), BigInt.from(-4));
    expect(r(-7, 2).truncate(), BigInt.from(-3));
    expect(r(5, 2).isTie, isTrue);
    expect(r(7, 3).isTie, isFalse);
  });

  test('stays exact beyond 2^53', () {
    final big = Rational(BigInt.parse('9007199254740993'), BigInt.from(3));
    expect(
      (big * Rational.fromInt(3)).numerator,
      BigInt.parse('9007199254740993'),
    );
  });

  test('PrototypeRounding rounds half-up at every point', () {
    const strategy = PrototypeRounding();
    for (final point in RoundingPoint.values) {
      expect(strategy.round(r(5, 2), point), 3);
      expect(strategy.round(r(-5, 2), point), -2);
    }
  });
}
