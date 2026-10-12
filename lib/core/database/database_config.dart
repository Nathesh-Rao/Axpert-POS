/// Configuration for the local database file.
///
/// The file name is infrastructure configuration only. Database placement and
/// platform-specific storage policy can be supplied by the provider.
final class DatabaseConfig {
  const DatabaseConfig({this.databaseName = 'axpert_pos'});

  /// Must be a valid Drift Web database name and native file name stem.
  final String databaseName;
}
