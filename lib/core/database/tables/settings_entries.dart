import 'package:drift/drift.dart';

/// Device-local settings rows (one per setting key). Never synced.
@DataClassName('SettingsEntry')
class SettingsEntries extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();

  TextColumn get valueJson => text()();

  /// UTC ISO 8601 text.
  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
