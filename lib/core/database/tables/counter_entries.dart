import 'package:drift/drift.dart';

import 'store_entries.dart';

/// Counters (registers) of a store (local-only, DEC-132).
@DataClassName('CounterEntry')
class CounterEntries extends Table {
  @override
  String get tableName => 'counters';

  TextColumn get id => text()();

  TextColumn get storeId => text().references(StoreEntries, #id)();

  TextColumn get name => text()();

  BoolColumn get active => boolean().withDefault(const Constant(true))();

  TextColumn get createdAt => text()();

  TextColumn get updatedAt => text()();

  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
