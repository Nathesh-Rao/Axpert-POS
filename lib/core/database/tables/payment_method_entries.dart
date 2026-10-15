import 'package:drift/drift.dart';

import 'store_entries.dart';

/// How a store takes payment (provisional, local-only, DEC-149). One row per
/// store and `code`; `payments.method_id` points here. Stamps are epoch
/// milliseconds.
@DataClassName('PaymentMethodEntry')
class PaymentMethodEntries extends Table {
  @override
  String get tableName => 'payment_methods';

  /// UUID v4.
  TextColumn get id => text()();

  TextColumn get storeId => text().references(StoreEntries, #id)();

  /// Stable key within the store: `cash`, `card`, `bank_transfer`,
  /// `mobile_money`. The `payments.method` text uses the same codes.
  TextColumn get code => text()();

  TextColumn get name => text()();

  /// cash, card, bank_transfer, mobile_money or other.
  TextColumn get methodType => text()
      .named('type')
      .check(
        // ignore: recursive_getters
        methodType.isIn(const [
          'cash',
          'card',
          'bank_transfer',
          'mobile_money',
          'other',
        ]),
      )();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// The cashier must enter a reference (transfer id, mobile receipt).
  BoolColumn get requiresReference =>
      boolean().withDefault(const Constant(false))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  /// Tombstone.
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {storeId, code},
  ];
}
