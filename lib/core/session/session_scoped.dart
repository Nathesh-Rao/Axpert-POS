/// A permanent controller that holds data of the signed-in session (store,
/// user, cart, lists). Sign-out calls [resetForSignOut]: it empties MEMORY
/// only and never writes, so saved data (held bills, the current cart row,
/// sales) stays in the database for the next sign-in.
abstract interface class SessionScoped {
  void resetForSignOut();
}
