import 'package:drift/drift.dart';

import 'product_entries.dart';
import 'store_entries.dart';
import 'user_entries.dart';

/// Stock on hand per store and product (provisional, local-only, DEC-148).
/// `quantity_milli` is exact (3 decimals); `products.stock` stays as the
/// whole-unit cache the screens read. `updated_at` is epoch milliseconds.
@DataClassName('InventoryBalanceEntry')
class InventoryBalanceEntries extends Table {
  @override
  String get tableName => 'inventory_balance';

  TextColumn get storeId => text().references(StoreEntries, #id)();

  TextColumn get productId => text().references(ProductEntries, #id)();

  IntColumn get quantityMilli => integer()();

  IntColumn get updatedAt => integer()();

  /// Reserved for the sync stage (A8); null today.
  IntColumn get serverVersion => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {storeId, productId};
}

/// Every change of a balance, append-only (a correction is a new row).
@TableIndex(
  name: 'inventory_tx_product',
  columns: {#storeId, #productId, #createdAt},
)
@TableIndex(name: 'inventory_tx_ref', columns: {#refType, #refId})
@DataClassName('InventoryTransactionEntry')
class InventoryTransactionEntries extends Table {
  @override
  String get tableName => 'inventory_transactions';

  /// UUID v4.
  TextColumn get id => text()();

  TextColumn get storeId => text().references(StoreEntries, #id)();

  TextColumn get productId => text().references(ProductEntries, #id)();

  /// Signed change in milli-units.
  IntColumn get quantityDeltaMilli => integer()();

  /// sale, return, purchase, adjustment, damage, transfer or opening.
  TextColumn get reason => text().check(
    // ignore: recursive_getters
    reason.isIn(const [
      'sale',
      'return',
      'purchase',
      'adjustment',
      'damage',
      'transfer',
      'opening',
    ]),
  )();

  /// What caused the change (`sale` plus the sale id, for example).
  TextColumn get refType => text().nullable()();

  TextColumn get refId => text().nullable()();

  TextColumn get userId => text().nullable().references(UserEntries, #id)();

  IntColumn get createdAt => integer()();

  TextColumn get note => text().withDefault(const Constant(''))();

  /// Tombstone, never set by the app today.
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
