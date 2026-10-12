import '../entities/session_entities.dart';

abstract interface class UserRepository {
  /// True when at least one active user exists (the login empty state).
  Future<bool> hasUsers();

  Future<UserCredential?> findByUsername(String username);

  /// The stores and counters [userId] may open, in store order.
  Future<List<StoreAccess>> accessFor(String userId);

  /// First active user with access (the `SKIP_ENTRY` session), or null.
  Future<UserCredential?> firstActive();
}

abstract interface class StoreRepository {
  /// True when at least one store exists (scoped mode, DEC-132).
  Future<bool> hasStores();

  Future<List<CurrencyRow>> loadCurrencies();

  Future<void> renameCounter(String counterId, String name);
}
