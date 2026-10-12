import 'package:drift/drift.dart';

/// Key-value state for one-way LocalStore to Drift copies (markers).
@DataClassName('MigrationStateEntry')
class MigrationStateEntries extends Table {
  @override
  String get tableName => 'migration_state';

  TextColumn get key => text()();

  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
