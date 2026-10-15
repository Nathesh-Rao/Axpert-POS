import 'package:drift/drift.dart';

import 'brand_entries.dart';
import 'category_entries.dart';
import 'store_entries.dart';
import 'unit_entries.dart';

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

  /// Owning store (v9). Null on legacy rows; while the `stores` table is
  /// empty every row is visible (DEC-132).
  TextColumn get storeId => text().nullable().references(StoreEntries, #id)();

  TextColumn get categoryId =>
      text().nullable().references(CategoryEntries, #id)();

  /// Base unit (v14, DEC-150). Nullable because SQLite cannot add a
  /// non-null FK column; the migration backfills `piece` and a null reads as
  /// piece.
  TextColumn get baseUnitId => text().nullable().references(UnitEntries, #id)();

  TextColumn get brandId => text().nullable().references(BrandEntries, #id)();

  /// Sibling SKUs of one product share a group; the label tells them apart.
  TextColumn get variantGroup => text().nullable()();

  TextColumn get variantLabel => text().nullable()();

  /// UTC ISO 8601 text.
  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  IntColumn get deletedAt => integer().nullable()();

  // Sync-readiness columns, nullable and unused (database_plan.md section 3).
  TextColumn get serverId => text().nullable()();

  IntColumn get serverVersion => integer().nullable()();

  TextColumn get deviceId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
