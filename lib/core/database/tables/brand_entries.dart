import 'package:drift/drift.dart';

/// Product brands (provisional, local-only, DEC-150). Minimal: a name and a
/// tombstone.
@DataClassName('BrandEntry')
class BrandEntries extends Table {
  @override
  String get tableName => 'brands';

  /// UUID v4.
  TextColumn get id => text()();

  TextColumn get name => text()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  /// Tombstone.
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
