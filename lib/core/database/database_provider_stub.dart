import 'axpert_database.dart';
import 'database_config.dart';
import 'database_provider.dart';

DatabaseProvider createDatabaseProvider(DatabaseConfig _) =>
    _UnsupportedDatabaseProvider();

final class _UnsupportedDatabaseProvider implements DatabaseProvider {
  @override
  Future<AxpertDatabase> open() =>
      Future.error(UnsupportedError('Native SQLite is unavailable here.'));

  @override
  Future<void> close() async {}
}
