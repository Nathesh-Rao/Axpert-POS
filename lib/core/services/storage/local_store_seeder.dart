import 'local_store.dart';

/// First-run seeding: writes [seed] only when [key] is missing and returns the
/// stored value either way.
abstract final class LocalStoreSeeder {
  static Future<Object?> seedIfMissing(
    LocalStore store,
    String key,
    Object? seed,
  ) async {
    if (await store.has(key)) return store.read(key);
    await store.write(key, seed);
    return seed;
  }
}
