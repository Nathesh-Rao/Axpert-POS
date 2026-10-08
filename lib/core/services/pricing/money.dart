import 'currency.dart';
import 'currency_registry.dart';
import 'decimal_parser.dart';

class CurrencyMismatch implements Exception {
  const CurrencyMismatch(this.a, this.b);

  final Currency a;
  final Currency b;

  @override
  String toString() => 'CurrencyMismatch: ${a.code} vs ${b.code}';
}

/// Integer minor units plus the currency they belong to.
class Money implements Comparable<Money> {
  const Money(this.minor, this.currency);

  const Money.zero(this.currency) : minor = 0;

  /// Parses plain decimal text at the currency exponent (half-up beyond it).
  factory Money.parse(String text, Currency currency) =>
      Money(DecimalParser.parseScaled(text, currency.exponent), currency);

  factory Money.fromJson(Map<String, dynamic> json) => Money(
    json['minor'] as int,
    CurrencyRegistry.byCode(json['currency'] as String),
  );

  final int minor;
  final Currency currency;

  bool get isZero => minor == 0;
  bool get isNegative => minor < 0;

  Money operator +(Money o) => Money(minor + _same(o).minor, currency);
  Money operator -(Money o) => Money(minor - _same(o).minor, currency);
  Money operator -() => Money(-minor, currency);

  @override
  int compareTo(Money other) => minor.compareTo(_same(other).minor);

  bool operator <(Money o) => compareTo(o) < 0;
  bool operator >(Money o) => compareTo(o) > 0;
  bool operator <=(Money o) => compareTo(o) <= 0;
  bool operator >=(Money o) => compareTo(o) >= 0;

  Money _same(Money o) {
    if (o.currency != currency) throw CurrencyMismatch(currency, o.currency);
    return o;
  }

  Map<String, dynamic> toJson() => {'minor': minor, 'currency': currency.code};

  @override
  bool operator ==(Object other) =>
      other is Money && other.minor == minor && other.currency == currency;

  @override
  int get hashCode => Object.hash(minor, currency);

  @override
  String toString() => '$minor ${currency.code}(minor)';
}
