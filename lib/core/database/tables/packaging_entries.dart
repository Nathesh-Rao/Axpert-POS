import 'package:drift/drift.dart';

import 'product_entries.dart';
import 'unit_entries.dart';

/// Packaging levels of a product above its base unit (provisional,
/// local-only, DEC-150): a pack of 6, a carton of 24. `quantity_base_milli`
/// is how many BASE units one package holds, in milli-units (24000 = 24).
/// `price_minor` null means derived (base price x quantity). Uniqueness of
/// (product_id, unit_id) among live rows is the partial index
/// `product_packagings_unique` created by the migration.
@DataClassName('PackagingEntry')
class PackagingEntries extends Table {
  @override
  String get tableName => 'product_packagings';

  /// UUID v4.
  TextColumn get id => text()();

  TextColumn get productId => text().references(ProductEntries, #id)();

  TextColumn get unitId => text().references(UnitEntries, #id)();

  TextColumn get name => text()();

  IntColumn get quantityBaseMilli => integer().check(
    // ignore: recursive_getters
    quantityBaseMilli.isBiggerThanValue(0),
  )();

  TextColumn get sku => text().nullable()();

  IntColumn get priceMinor => integer().nullable()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  /// Tombstone.
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
