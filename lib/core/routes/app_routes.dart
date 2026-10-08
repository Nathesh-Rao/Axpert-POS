/// Named routes. The page enum is the single list of the seven destinations.
enum AppPage {
  pos('/'),
  products('/products'),
  customers('/customers'),
  sales('/sales'),
  returns('/returns'),
  reports('/reports'),
  more('/more');

  const AppPage(this.path);

  final String path;

  /// Unknown paths fall through to POS (prototype behavior).
  static AppPage fromPath(String? path) => AppPage.values.firstWhere(
    (page) => page.path == path,
    orElse: () => AppPage.pos,
  );
}

abstract final class AppRoutes {
  static const String pos = '/';
  static const String products = '/products';
  static const String customers = '/customers';
  static const String sales = '/sales';
  static const String returns = '/returns';
  static const String reports = '/reports';
  static const String more = '/more';
}
