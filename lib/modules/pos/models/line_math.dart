import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/rational.dart';
import 'cart_line.dart';

/// Per-line display amount (prototype `lineTotal`), exact then rounded
/// half-up once for display (KG-001).
abstract final class LineMath {
  static final BigInt _tenThousand = BigInt.from(10000);
  static final BigInt _thousand = BigInt.from(1000);

  static Money lineTotal(CartLine line) {
    final unitOff = line.offer?.unitOffMinor ?? 0;
    final unit = unitOff == 0
        ? BigInt.from(line.price.minor)
        : BigInt.from(
            line.price.minor > unitOff ? line.price.minor - unitOff : 0,
          );
    final numerator =
        BigInt.from(line.qty.milli) *
        unit *
        (_tenThousand - BigInt.from(line.discount.value));
    final exact = Rational(numerator, _thousand * _tenThousand);
    return Money(exact.roundHalfUp().toInt(), line.price.currency);
  }
}
