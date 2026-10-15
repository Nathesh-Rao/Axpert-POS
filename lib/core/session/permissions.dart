/// What a signed-in role may do. `users.role` is plain text (admin, manager,
/// cashier); this is the one place that reads it for catalog changes.
abstract final class CatalogPermissions {
  static const String admin = 'admin';
  static const String manager = 'manager';

  /// Add, edit, deactivate, adjust stock, set up offers.
  static bool canManageCatalog(String? role) =>
      role == admin || role == manager;
}
