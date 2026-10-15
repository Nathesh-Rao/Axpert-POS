/// What a signed-in role may do. `users.role` is plain text (admin, manager,
/// cashier); this is the one place that reads it for catalog changes.
abstract final class CatalogPermissions {
  static const String admin = 'admin';
  static const String manager = 'manager';

  /// Add, edit, deactivate, adjust stock, set up offers.
  static bool canManageCatalog(String? role) =>
      role == admin || role == manager;
}

/// Who may see and change the store configuration (country, currency, forex,
/// tax). The controller re-checks this on every command.
abstract final class StoreConfigPermissions {
  /// Only an admin changes it.
  static bool canEdit(String? role) => role == CatalogPermissions.admin;

  /// A manager may look, a cashier has no access.
  static bool canView(String? role) =>
      role == CatalogPermissions.admin || role == CatalogPermissions.manager;
}
