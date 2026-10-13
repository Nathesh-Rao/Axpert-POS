import 'package:drift/drift.dart';

import 'currency_entries.dart';
import 'store_entries.dart';

/// Foreign currencies a store converts its total into (local-only). `rate_micro`
/// is the integer rate scaled by 1,000,000: 1 foreign unit = `rate_micro / 1e6`
/// units of the store's currency.
@DataClassName('StoreForexEntry')
class StoreForexEntries extends Table {
  @override
  String get tableName => 'store_forex';

  TextColumn get id => text()();

  TextColumn get storeId => text().references(StoreEntries, #id)();

  TextColumn get foreignCurrencyCode =>
      text().references(CurrencyEntries, #code)();

  IntColumn get rateMicro => integer()();

  BoolColumn get active => boolean().withDefault(const Constant(true))();

  IntColumn get position => integer().withDefault(const Constant(0))();

  TextColumn get createdAt => text()();

  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {storeId, foreignCurrencyCode},
  ];
}
