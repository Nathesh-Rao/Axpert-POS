import 'package:drift/drift.dart';

import 'store_entries.dart';

/// Product categories and subcategories (local-only, DEC-132). `icon_key`
/// maps to a Lucide icon in code; a null `parent_id` marks a top category.
@DataClassName('CategoryEntry')
class CategoryEntries extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();

  /// Null = shared by every store.
  TextColumn get storeId => text().nullable().references(StoreEntries, #id)();

  TextColumn get name => text()();

  TextColumn get parentId => text().nullable()();

  TextColumn get iconKey => text().withDefault(const Constant(''))();

  IntColumn get position => integer().withDefault(const Constant(0))();

  TextColumn get createdAt => text()();

  TextColumn get updatedAt => text()();

  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
