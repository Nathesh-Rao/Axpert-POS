import '../domain/entities/session_entities.dart';
import '../domain/repositories/session_repositories.dart';

/// Test and empty-database implementations: they hold whatever they are given
/// (nothing by default).
class InMemoryUserRepository implements UserRepository {
  InMemoryUserRepository({
    this.users = const <UserCredential>[],
    this.access = const <String, List<StoreAccess>>{},
  });

  final List<UserCredential> users;
  final Map<String, List<StoreAccess>> access;

  @override
  Future<bool> hasUsers() async => users.isNotEmpty;

  @override
  Future<UserCredential?> findByUsername(String username) async {
    for (final u in users) {
      if (u.user.username == username) return u;
    }
    return null;
  }

  @override
  Future<List<StoreAccess>> accessFor(String userId) async =>
      access[userId] ?? const <StoreAccess>[];

  @override
  Future<UserCredential?> firstActive() async =>
      users.isEmpty ? null : users.first;
}

class InMemoryStoreRepository implements StoreRepository {
  InMemoryStoreRepository({this.currencies = const <CurrencyRow>[]});

  final List<CurrencyRow> currencies;

  @override
  Future<bool> hasStores() async => false;

  final Map<String, String> renamed = <String, String>{};

  @override
  Future<List<CurrencyRow>> loadCurrencies() async => currencies;

  @override
  Future<void> renameCounter(String counterId, String name) async {
    renamed[counterId] = name;
  }
}
