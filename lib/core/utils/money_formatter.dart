import '../services/pricing/currency.dart';
import '../services/pricing/money.dart';

/// Formats money per currency: exponent, grouping (lakh or thousands), symbol.
class MoneyFormatter {
  const MoneyFormatter._();

  static String format(Money money, {bool symbol = true}) =>
      formatMinor(money.minor, money.currency, symbol: symbol);

  static String formatMinor(
    int minor,
    Currency currency, {
    bool symbol = true,
  }) {
    final negative = minor < 0;
    final digits = (negative ? -minor : minor).toString().padLeft(
      currency.exponent + 1,
      '0',
    );
    final cut = digits.length - currency.exponent;
    final whole = _group(digits.substring(0, cut), currency.grouping);
    final frac = currency.exponent == 0 ? '' : '.${digits.substring(cut)}';
    return '${negative ? '-' : ''}${symbol ? currency.symbol : ''}$whole$frac';
  }

  static String _group(String digits, DigitGrouping grouping) {
    if (digits.length <= 3) return digits;
    final tail = digits.substring(digits.length - 3);
    var head = digits.substring(0, digits.length - 3);
    final size = grouping == DigitGrouping.lakh ? 2 : 3;
    final parts = <String>[];
    while (head.length > size) {
      parts.insert(0, head.substring(head.length - size));
      head = head.substring(0, head.length - size);
    }
    parts.insert(0, head);
    return '${parts.join(',')},$tail';
  }
}
