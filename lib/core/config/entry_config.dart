import '../routes/app_routes.dart';

/// Where the app starts. The demo entry flow (splash, login, landing) is on by
/// default; `--dart-define=SKIP_ENTRY=true` starts on the landing page, for
/// the browser checks and the tests that expect the POS screen.
abstract final class EntryConfig {
  static const bool skip = bool.fromEnvironment('SKIP_ENTRY');

  /// `--dart-define=SKIP_ENTRY_USER=cashier2`: which user `SKIP_ENTRY` signs in
  /// (default: the first active user).
  static const String skipUser = String.fromEnvironment('SKIP_ENTRY_USER');

  static String get initialRoute => skip ? AppRoutes.pos : AppRoutes.splash;
}
