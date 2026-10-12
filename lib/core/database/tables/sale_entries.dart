import 'package:drift/drift.dart';

import 'customer_entries.dart';

/// Completed sales (provisional, local-only, DEC-124/129). `id` is the UUID v4
/// (the `saleId` of new sales, generated for legacy sales); `number` is the
/// human number `AX000001`, DISPLAY ONLY and NOT unique (KG-008: duplicates are
/// imported and reported). A completed sale is immutable except for returns:
/// the quantities live in `sale_lines.returned_qty_milli`, `returned_order`
/// only keeps the order of the prototype's `returned` map so the LocalStore
/// mirror stays byte-identical. `deleted_at` is never set by the app; only the
/// whole-list `save` API can tombstone (contract parity with the Mock).
@DataClassName('SaleEntry')
@TableIndex(name: 'sales_position', columns: {#position})
class SaleEntries extends Table {
  @override
  String get tableName => 'sales';

  TextColumn get id => text()();

  TextColumn get number => text()();

  /// Index in the app's sales list (the list order is observable).
  IntColumn get position => integer()();

  /// `Sale.date` verbatim (UTC ISO text, never parsed here).
  TextColumn get occurredAt => text()();

  TextColumn get storeName => text()();

  TextColumn get customerName => text()();

  /// `cart.customer` verbatim (the legacy customer id; needed for a byte-exact
  /// cart snapshot).
  TextColumn get customerLegacyId => text()();

  /// Resolved link to `customers.id`; null until the customer row is known.
  /// Derived data: filled once, never overwritten.
  TextColumn get customerId =>
      text().nullable().references(CustomerEntries, #id)();

  /// PROPOSED default INR (DEC-124).
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();

  /// Cash, Card or Credit as stored by the app.
  TextColumn get mode => text()();

  // Cart snapshot (the sale's `cart` JSON minus the lines).
  TextColumn get saleType => text()();

  TextColumn get billDiscountType => text()();

  IntColumn get billDiscountBp => integer()();

  IntColumn get billDiscountMinor => integer()();

  TextColumn get discountReason => text()();

  IntColumn get pointsRedeemed => integer()();

  TextColumn get note => text()();

  // Totals.
  IntColumn get items => integer()();

  IntColumn get qtyMilli => integer()();

  IntColumn get valueMinor => integer()();

  IntColumn get subtotalMinor => integer()();

  IntColumn get discountMinor => integer()();

  IntColumn get taxMinor => integer()();

  IntColumn get pointsMinor => integer()();

  IntColumn get totalMinor => integer()();

  IntColumn get tenderedMinor => integer()();

  IntColumn get changeMinor => integer()();

  /// JSON array of product ids, first returned first.
  TextColumn get returnedOrder => text().withDefault(const Constant('[]'))();

  /// UTC ISO 8601 text; `updated_at` changes only when a return is applied.
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
