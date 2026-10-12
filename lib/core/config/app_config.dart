enum AppEnvironment { development, test, production }

/// Where the settings live (DEC-125). `drift` is the default; `localStore` is
/// the rollback (set `--dart-define=SETTINGS_BACKEND=localStore`); `mock` is
/// for tests (plain Mock repository, no Drift, no stale marking).
enum SettingsBackend {
  drift,
  localStore,
  mock;

  static const String _fromEnvironment = String.fromEnvironment(
    'SETTINGS_BACKEND',
    defaultValue: 'drift',
  );

  /// The compile-time choice; anything but `localStore` means `drift`.
  static SettingsBackend get configured =>
      _fromEnvironment == 'localStore' ? localStore : drift;
}

/// Where the customers live (DEC-126); same meaning as [SettingsBackend]
/// (`--dart-define=CUSTOMERS_BACKEND=localStore` rolls back).
enum CustomersBackend {
  drift,
  localStore,
  mock;

  static const String _fromEnvironment = String.fromEnvironment(
    'CUSTOMERS_BACKEND',
    defaultValue: 'drift',
  );

  static CustomersBackend get configured =>
      _fromEnvironment == 'localStore' ? localStore : drift;
}

/// Where the held bills live (DEC-127); same meaning as [SettingsBackend]
/// (`--dart-define=HELD_BACKEND=localStore` rolls back).
enum HeldBackend {
  drift,
  localStore,
  mock;

  static const String _fromEnvironment = String.fromEnvironment(
    'HELD_BACKEND',
    defaultValue: 'drift',
  );

  static HeldBackend get configured =>
      _fromEnvironment == 'localStore' ? localStore : drift;
}

/// Where the products live (DEC-128); same meaning as [SettingsBackend]
/// (`--dart-define=PRODUCTS_BACKEND=localStore` rolls back).
enum ProductsBackend {
  drift,
  localStore,
  mock;

  static const String _fromEnvironment = String.fromEnvironment(
    'PRODUCTS_BACKEND',
    defaultValue: 'drift',
  );

  static ProductsBackend get configured =>
      _fromEnvironment == 'localStore' ? localStore : drift;
}

/// Where the sales ledger lives (DEC-129); same meaning as [SettingsBackend]
/// (`--dart-define=SALES_BACKEND=localStore` rolls back sales, checkout
/// transaction and refund transaction to the LocalStore path).
enum SalesBackend {
  drift,
  localStore,
  mock;

  static const String _fromEnvironment = String.fromEnvironment(
    'SALES_BACKEND',
    defaultValue: 'drift',
  );

  static SalesBackend get configured =>
      _fromEnvironment == 'localStore' ? localStore : drift;
}

abstract interface class AppConfig {
  AppEnvironment get environment;

  bool get mockDataEnabled;

  Uri? get apiBaseUrl;

  SettingsBackend get settingsBackend;

  CustomersBackend get customersBackend;

  HeldBackend get heldBackend;

  ProductsBackend get productsBackend;

  SalesBackend get salesBackend;
}

final class DevelopmentAppConfig implements AppConfig {
  const DevelopmentAppConfig({
    this.apiBaseUrl,
    SettingsBackend? settingsBackend,
    CustomersBackend? customersBackend,
    HeldBackend? heldBackend,
    ProductsBackend? productsBackend,
    SalesBackend? salesBackend,
  }) : _settingsBackend = settingsBackend,
       _customersBackend = customersBackend,
       _heldBackend = heldBackend,
       _productsBackend = productsBackend,
       _salesBackend = salesBackend;

  final SettingsBackend? _settingsBackend;
  final CustomersBackend? _customersBackend;
  final HeldBackend? _heldBackend;
  final ProductsBackend? _productsBackend;
  final SalesBackend? _salesBackend;

  @override
  AppEnvironment get environment => AppEnvironment.development;

  @override
  bool get mockDataEnabled => true;

  @override
  final Uri? apiBaseUrl;

  @override
  SettingsBackend get settingsBackend =>
      _settingsBackend ?? SettingsBackend.configured;

  @override
  CustomersBackend get customersBackend =>
      _customersBackend ?? CustomersBackend.configured;

  @override
  HeldBackend get heldBackend => _heldBackend ?? HeldBackend.configured;

  @override
  ProductsBackend get productsBackend =>
      _productsBackend ?? ProductsBackend.configured;

  @override
  SalesBackend get salesBackend => _salesBackend ?? SalesBackend.configured;
}
