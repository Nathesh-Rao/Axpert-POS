/// Secure persistence boundary for opaque credentials and device secrets.
///
/// Implementations must use approved secure storage. This interface does not
/// define whether values are access tokens, refresh tokens, or device secrets.
abstract interface class SecureCredentialStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> delete(String key);
}
