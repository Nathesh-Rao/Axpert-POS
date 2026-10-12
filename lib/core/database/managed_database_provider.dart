import 'package:drift/drift.dart';

import 'axpert_database.dart';
import 'database_provider.dart';

/// Shares database initialization and lifecycle across platform providers.
abstract base class ManagedDatabaseProvider implements DatabaseProvider {
  ManagedDatabaseProvider(this._createExecutor);

  final Future<QueryExecutor> Function() _createExecutor;
  Future<AxpertDatabase>? _databaseFuture;

  @override
  Future<AxpertDatabase> open() {
    final existing = _databaseFuture;
    if (existing != null) return existing;

    final opening = _open();
    _databaseFuture = opening;
    return opening.catchError((Object error, StackTrace stackTrace) {
      if (identical(_databaseFuture, opening)) _databaseFuture = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<AxpertDatabase> _open() async {
    final database = AxpertDatabase(await _createExecutor());
    // Opening a Drift database runs schema creation/migrations and beforeOpen.
    await database.customSelect('SELECT 1').get();
    return database;
  }

  @override
  Future<void> close() async {
    final opening = _databaseFuture;
    _databaseFuture = null;
    if (opening != null) await (await opening).close();
  }
}
