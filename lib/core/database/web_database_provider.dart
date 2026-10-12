import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import 'database_config.dart';
import 'database_provider.dart';
import 'managed_database_provider.dart';

DatabaseProvider createDatabaseProvider(DatabaseConfig config) =>
    WebDatabaseProvider(config: config);

/// Opens browser-local persistence through Drift's WASM/worker implementation.
final class WebDatabaseProvider extends ManagedDatabaseProvider {
  WebDatabaseProvider({required this.config})
    : super(() => _createExecutor(config));

  final DatabaseConfig config;

  static Future<QueryExecutor> _createExecutor(DatabaseConfig config) async {
    final result = await WasmDatabase.open(
      databaseName: config.databaseName,
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.js'),
    );
    return result.resolvedExecutor;
  }
}
