import 'package:drift/drift.dart';

import 'currency_entries.dart';

/// Stores (local-only, DEC-132). `currency_code` and `region` are the plug
/// points for the regional tax work (Batch 2b).
@DataClassName('StoreEntry')
class StoreEntries extends Table {
  @override
  String get tableName => 'stores';

  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get address => text().withDefault(const Constant(''))();

  TextColumn get phone => text().withDefault(const Constant(''))();

  TextColumn get taxId => text().withDefault(const Constant(''))();

  TextColumn get receiptHeader => text().withDefault(const Constant(''))();

  TextColumn get receiptFooter => text().withDefault(const Constant(''))();

  TextColumn get currencyCode => text().references(CurrencyEntries, #code)();

  /// Country or region code for tax selection (not used yet).
  TextColumn get region => text().withDefault(const Constant(''))();

  BoolColumn get active => boolean().withDefault(const Constant(true))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  IntColumn get deletedAt => integer().nullable()();

  /// Per-store stock rule (DEC-148): false = a sale that would take stock
  /// below zero is refused (today's behavior); true = it is allowed with a
  /// warning.
  BoolColumn get allowNegativeStock =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
