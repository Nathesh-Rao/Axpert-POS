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

  static Currency byCode(String code) => all.firstWhere(
    (c) => c.code == code,
    orElse: () => throw ArgumentError('Unknown currency $code'),
  );
}
