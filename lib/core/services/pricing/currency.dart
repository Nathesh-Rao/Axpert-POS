/// How digits are grouped in the integer part.
enum DigitGrouping { thousands, lakh }

class Currency {
  const Currency({
    required this.code,
    required this.symbol,
    required this.exponent,
    required this.grouping,
  });

  final String code;
  final String symbol;

  /// Decimal places of the minor unit (0, 2 or 3).
  final int exponent;
  final DigitGrouping grouping;

  @override
  bool operator ==(Object other) => other is Currency && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}
