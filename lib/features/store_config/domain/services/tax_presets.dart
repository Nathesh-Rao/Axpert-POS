/// The labels offered in the component picker; "Custom" is a separate entry
/// where the admin types any label.
abstract final class TaxPresets {
  static const List<String> all = <String>[
    'GST',
    'CGST',
    'SGST',
    'IGST',
    'VAT',
    'Sales tax',
    'Service charge',
  ];

  /// Labels used in India only (a hint, never a rule).
  static const List<String> indian = <String>['GST', 'CGST', 'SGST', 'IGST'];
}

/// A country the picker offers; the currency is only a default.
class CountryHint {
  const CountryHint(this.code, this.name, this.currencyCode, this.common);

  final String code;
  final String name;
  final String currencyCode;

  /// Presets common in the country, listed first.
  final List<String> common;
}

/// Country hints: ordering of presets and the default currency. Country never
/// decides tax; every preset stays selectable.
abstract final class CountryHints {
  static const List<String> _vat = <String>['VAT', 'Service charge'];

  static const List<CountryHint> countries = <CountryHint>[
    CountryHint('IN', 'India', 'INR', <String>['GST', 'CGST', 'SGST', 'IGST']),
    CountryHint('UG', 'Uganda', 'UGX', _vat),
    CountryHint('KE', 'Kenya', 'KES', _vat),
    CountryHint('RW', 'Rwanda', 'RWF', _vat),
    CountryHint('NG', 'Nigeria', 'NGN', _vat),
    CountryHint('GH', 'Ghana', 'GHS', _vat),
    CountryHint('ZA', 'South Africa', 'ZAR', _vat),
    CountryHint('TN', 'Tunisia', 'TND', _vat),
    CountryHint('SN', 'Senegal', 'XOF', _vat),
    CountryHint('CI', "Côte d'Ivoire", 'XOF', _vat),
    CountryHint('AE', 'United Arab Emirates', 'AED', _vat),
    CountryHint('DE', 'Germany', 'EUR', _vat),
    CountryHint('FR', 'France', 'EUR', _vat),
    CountryHint('US', 'United States', 'USD', <String>['Sales tax']),
  ];

  static CountryHint? byCode(String code) {
    for (final c in countries) {
      if (c.code == code) return c;
    }
    return null;
  }

  /// Every preset, the ones common for [country] first (the rest keep their
  /// order).
  static List<String> presetsFor(String country) {
    final common = byCode(country)?.common ?? const <String>[];
    return <String>[
      ...common,
      for (final p in TaxPresets.all)
        if (!common.contains(p)) p,
    ];
  }

  /// True when [label] is an Indian tax name and [country] is not India: the
  /// page shows a non-blocking warning ("GST is used in India. Continue?").
  static bool warnsIndianLabel(String country, String label) {
    if (country == 'IN') return false;
    final l = label.trim().toLowerCase();
    return TaxPresets.indian.any((p) => p.toLowerCase() == l);
  }

  /// The default currency of [country], or null for an unknown one.
  static String? defaultCurrency(String country) =>
      byCode(country)?.currencyCode;
}
