import '../entities/store_config.dart';

abstract interface class StoreConfigRepository {
  /// The editable configuration of [storeId]; slabs fall back to the legacy
  /// regime of the store's country (components from its split parts).
  Future<StoreConfig> load(String storeId);

  /// Replaces the store row fields, the forex rows and the slabs of the store
  /// in one transaction. Applies to new sales only.
  Future<void> save(StoreConfig config);

  /// True when the store has any sale (the currency is then locked).
  Future<bool> storeHasSales(String storeId);

  /// Products of the store per tax rate (basis points), active products only.
  Future<Map<int, int>> productCountsByRate(String storeId);
}
