import 'package:drift/drift.dart';

/// Ids inserted by the DemoSeeder, so a reseed deletes only seeded rows
/// (DEC-135).
@DataClassName('SeedManifestEntry')
class SeedManifestEntries extends Table {
  @override
  String get tableName => 'seed_manifest';

  TextColumn get tableNameValue => text().named('table_name')();

  TextColumn get rowId => text().named('row_id')();

  @override
  Set<Column<Object>> get primaryKey => {tableNameValue, rowId};
}
