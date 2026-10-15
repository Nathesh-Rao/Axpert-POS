import '../domain/entities/store_config.dart';
import '../domain/repositories/store_config_repository.dart';

/// In memory (tests and previews).
class InMemoryStoreConfigRepository implements StoreConfigRepository {
  InMemoryStoreConfigRepository(
    this.configs, {
    this.hasSales = false,
    this.rateCounts = const <int, int>{},
  });

  final Map<String, StoreConfig> configs;
  bool hasSales;
  Map<int, int> rateCounts;
  int saves = 0;

  @override
  Future<StoreConfig> load(String storeId) async => configs[storeId]!;

  @override
  Future<void> save(StoreConfig config) async {
    saves++;
    configs[config.storeId] = config;
  }

  @override
  Future<bool> storeHasSales(String storeId) async => hasSales;

  @override
  Future<Map<int, int>> productCountsByRate(String storeId) async => rateCounts;
}
