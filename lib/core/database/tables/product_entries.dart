import 'package:drift/drift.dart';

/// Products (provisional, local-only, DEC-124/128). `legacy_id` is the app's
/// integer `Product.id` (a list index, referenced by sale snapshots and the
/// `returned` map); `id` is the UUID v4 key. `code` and `barcode` are NOT
/// unique (axpert A3 is open); duplicates are reported by the copy.
@DataClassName('ProductEntry')
@TableIndex(name: 'products_position', columns: {#position})
class ProductEntries extends Table {
  @override
  String get tableName => 'products';

  TextColumn get id => text()();

  IntColumn get legacyId => integer().unique()();

  /// Index in the app's product list (the list order is observable).
  IntColumn get position => integer()();

  TextColumn get name => text()();

  TextColumn get code => text()();

  TextColumn get barcode => text()();

  IntColumn get priceMinor => integer()();

  /// PROPOSED default INR (DEC-124); the price's currency code.
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();

  TextColumn get category => text()();

  TextColumn get sub => text()();

  /// Whole units.
  IntColumn get stock => integer()();

  /// Basis points; the JSON keeps the prototype's percent number.
  IntColumn get gstBp => integer()();

  /// Asset number or -1 for none.
  IntColumn get image => integer()();

  BoolColumn get favourite => boolean()();

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
