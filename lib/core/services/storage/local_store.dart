/// Async JSON key-value storage. Values are plain JSON (bool, int, String,
/// List, Map); nothing here knows about the prototype's data shapes.
abstract interface class LocalStore {
  Future<Object?> read(String key);

  Future<void> write(String key, Object? json);

  Future<void> remove(String key);

  Future<bool> has(String key);
}
