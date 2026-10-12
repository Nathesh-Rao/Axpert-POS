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

  TextColumn get createdAt => text()();

  TextColumn get updatedAt => text()();

  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
