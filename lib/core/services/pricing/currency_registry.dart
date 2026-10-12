import 'currency.dart';

class CurrencyRegistry {
  const CurrencyRegistry._();

  static const Currency inr = Currency(
    code: 'INR',
    symbol: '₹',
    exponent: 2,
    grouping: DigitGrouping.lakh,
  );
  static const Currency usd = Currency(
    code: 'USD',
    symbol: r'$',
    exponent: 2,
    grouping: DigitGrouping.thousands,
  );
  static const Currency eur = Currency(
    code: 'EUR',
    symbol: '€',
    exponent: 2,
    grouping: DigitGrouping.thousands,
  );
  static const Currency aed = Currency(
    code: 'AED',
    symbol: 'AED ',
    exponent: 2,
    grouping: DigitGrouping.thousands,
  );
  static const Currency kes = Currency(
    code: 'KES',
    symbol: 'KSh ',
    exponent: 2,
    grouping: DigitGrouping.thousands,
  );
  static const Currency ngn = Currency(
    code: 'NGN',
    symbol: '₦',
    exponent: 2,
    grouping: DigitGrouping.thousands,
  );
  static const Currency ghs = Currency(
    code: 'GHS',
    symbol: 'GH₵',
    exponent: 2,
    grouping: DigitGrouping.thousands,
  );
  static const Currency zar = Currency(
    code: 'ZAR',
    symbol: 'R ',
    exponent: 2,
    grouping: DigitGrouping.thousands,
  );
  static const Currency ugx = Currency(
    code: 'UGX',
    symbol: 'USh ',
    exponent: 0,
    grouping: DigitGrouping.thousands,
  );
  static const Currency rwf = Currency(
    code: 'RWF',
    symbol: 'RF ',
    exponent: 0,
    grouping: DigitGrouping.thousands,
  );
  static const Currency xof = Currency(
    code: 'XOF',
    symbol: 'CFA ',
    exponent: 0,
    grouping: DigitGrouping.thousands,
  );
  static const Currency tnd = Currency(
    code: 'TND',
    symbol: 'DT ',
    exponent: 3,
    grouping: DigitGrouping.thousands,
  );

  static const List<Currency> all = [
    inr,
    usd,
    eur,
    aed,
    kes,
    ngn,
    ghs,
    zar,
    ugx,
    rwf,
    xof,
    tnd,
  ];

  static final Map<String, Currency> _loaded = <String, Currency>{};

  /// Currencies read from the `currencies` table at start-up (DEC-132). They
  /// take precedence over the built-in list, which stays as the fallback for
  /// legacy rows and tests. Equality is by code, so replacing is safe.
  static void register(Iterable<Currency> currencies) {
    for (final c in currencies) {
      _loaded[c.code] = c;
    }
  }

  /// Forgets the loaded currencies (tests).
  static void resetLoaded() => _loaded.clear();

  static Currency byCode(String code) =>
      _loaded[code] ??
      all.firstWhere(
        (c) => c.code == code,
        orElse: () => throw ArgumentError('Unknown currency $code'),
      );
}
