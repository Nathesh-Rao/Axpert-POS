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

abstract interface class AppConfig {
  AppEnvironment get environment;

  bool get mockDataEnabled;

  Uri? get apiBaseUrl;

  SettingsBackend get settingsBackend;

  CustomersBackend get customersBackend;
}

final class DevelopmentAppConfig implements AppConfig {
  const DevelopmentAppConfig({
    this.apiBaseUrl,
    SettingsBackend? settingsBackend,
    CustomersBackend? customersBackend,
  }) : _settingsBackend = settingsBackend,
       _customersBackend = customersBackend;

  final SettingsBackend? _settingsBackend;
  final CustomersBackend? _customersBackend;

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
}
