import 'package:drift/drift.dart';

import 'packaging_entries.dart';
import 'product_entries.dart';
import 'store_entries.dart';

/// Barcodes of a product (provisional, local-only, DEC-150). `packaging_id`
/// null means the base unit. `store_id` copies the product's store (products
/// are scoped by `products.store_id`); a barcode is unique per store among
/// live rows (partial index `product_barcodes_unique`, null store = one
/// shared scope). `products.barcode` stays as the base-barcode cache.
@DataClassName('BarcodeEntry')
class BarcodeEntries extends Table {
  @override
  String get tableName => 'product_barcodes';

  /// UUID v4.
  TextColumn get id => text()();

  TextColumn get productId => text().references(ProductEntries, #id)();

  TextColumn get packagingId =>
      text().nullable().references(PackagingEntries, #id)();

  TextColumn get storeId => text().nullable().references(StoreEntries, #id)();

  TextColumn get barcode => text()();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  /// Tombstone.
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
