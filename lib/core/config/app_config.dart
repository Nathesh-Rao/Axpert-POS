enum AppEnvironment { development, test, production }

abstract interface class AppConfig {
  AppEnvironment get environment;

  bool get mockDataEnabled;

  Uri? get apiBaseUrl;
}

final class DevelopmentAppConfig implements AppConfig {
  const DevelopmentAppConfig({this.apiBaseUrl});

  @override
  AppEnvironment get environment => AppEnvironment.development;

  @override
  bool get mockDataEnabled => true;

  @override
  final Uri? apiBaseUrl;
}
