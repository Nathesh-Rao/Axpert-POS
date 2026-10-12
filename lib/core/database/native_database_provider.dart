import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database_config.dart';
import 'database_provider.dart';
import 'managed_database_provider.dart';

DatabaseProvider createDatabaseProvider(DatabaseConfig config) =>
    NativeDatabaseProvider(config: config);

/// Opens the app's persistent SQLite database in the platform support folder.
///
/// An executor can be supplied by tests to use an in-memory SQLite database.
final class NativeDatabaseProvider extends ManagedDatabaseProvider {
  NativeDatabaseProvider({required this.config, QueryExecutor? executor})
    : super(() => _createExecutor(config, executor));

  final DatabaseConfig config;

  static Future<QueryExecutor> _createExecutor(
    DatabaseConfig config,
    QueryExecutor? executor,
  ) async {
    if (executor != null) return executor;
    final supportDirectory = await getApplicationSupportDirectory();
    final databaseFile = File(
      p.join(supportDirectory.path, '${config.databaseName}.sqlite'),
    );
    return NativeDatabase.createInBackground(databaseFile);
  }
}
