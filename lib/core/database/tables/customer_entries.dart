import 'package:drift/drift.dart';

/// Customers (provisional, local-only, DEC-124/126). `legacy_id` is the app's
/// `Customer.id` (`walk`, `1`..`3`, clock ids); `id` is the UUID v4 key.
@DataClassName('CustomerEntry')
class CustomerEntries extends Table {
  @override
  String get tableName => 'customers';

  TextColumn get id => text()();

  TextColumn get legacyId => text().unique()();

  /// Index in the app's customer list (the list order is observable).
  IntColumn get position => integer()();

  TextColumn get name => text()();

  TextColumn get phone => text()();

  TextColumn get email => text()();

  TextColumn get memberNo => text()();

  /// Whole loyalty points (not money); may be negative as in the app today.
  IntColumn get points => integer()();

  /// UTC ISO 8601 text.
  TextColumn get createdAt => text()();

  TextColumn get updatedAt => text()();

  TextColumn get deletedAt => text().nullable()();

  // Sync-readiness columns, nullable and unused (database_plan.md section 3).
  TextColumn get serverId => text().nullable()();

  IntColumn get serverVersion => integer().nullable()();

  TextColumn get deviceId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
