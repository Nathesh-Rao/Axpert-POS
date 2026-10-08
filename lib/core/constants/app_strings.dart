import 'en_app_strings.dart';

/// All user-facing strings (English only for now). One method per message,
/// named parameters, values pre-formatted by the caller, no concatenation in
/// views. Method names are the future ARB keys, so `gen_l10n` can replace this
/// class with the same signatures (DEC-034).
abstract class AppStrings {
  const AppStrings();

  /// The active strings. Swapped when translations arrive.
  static AppStrings current = const EnAppStrings();

  String appTitle();

  // Navigation and pages
  String navPos();
  String navProducts();
  String navCustomers();
  String navSales();
  String navReturns();
  String navReports();
  String navMore();
  String titleSettings();
  String workspaceEyebrow();
}
