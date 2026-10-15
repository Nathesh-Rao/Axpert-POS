import 'package:drift/drift.dart';

import 'product_entries.dart';
import 'store_entries.dart';

/// Automatic offers (local-only, Drift-only, DEC-134): `discount` (percent or
/// fixed amount per unit on one product), `promotion` (Buy 1 Get 1: the whole
/// product at `percent_bp`) and `gift_tier` (`gift_product_id` is free from
/// `min_cart_minor`). Money columns are minor units of `currency_code`.
@DataClassName('OfferEntry')
class OfferEntries extends Table {
  @override
  String get tableName => 'offers';

  TextColumn get id => text()();

  TextColumn get kind =>
      // ignore: recursive_getters
      text().check(kind.isIn(const ['discount', 'promotion', 'gift_tier']))();

  TextColumn get name => text()();

  /// Null = every store.
  TextColumn get storeId => text().nullable().references(StoreEntries, #id)();

  TextColumn get productId =>
      text().nullable().references(ProductEntries, #id)();

  // ignore: recursive_getters
  IntColumn get percentBp => integer().nullable().check(
    // ignore: recursive_getters
    percentBp.isNull() | percentBp.isBetweenValues(0, 10000),
  )();

  IntColumn get fixedAmountMinor => integer().nullable()();

  TextColumn get currencyCode => text().nullable()();

  IntColumn get minCartMinor => integer().nullable()();

  TextColumn get giftProductId =>
      text().nullable().references(ProductEntries, #id)();

  /// UTC ISO 8601 text; null = no bound.
  IntColumn get startsAt => integer().nullable()();

  IntColumn get endsAt => integer().nullable()();

  BoolColumn get active => boolean().withDefault(const Constant(true))();

  IntColumn get priority => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK ((kind = 'discount' AND product_id IS NOT NULL AND "
        '((percent_bp IS NOT NULL) <> (fixed_amount_minor IS NOT NULL)) AND '
        '(fixed_amount_minor IS NULL OR currency_code IS NOT NULL)) OR '
        "(kind = 'promotion' AND product_id IS NOT NULL AND "
        'percent_bp IS NOT NULL) OR '
        "(kind = 'gift_tier' AND gift_product_id IS NOT NULL AND "
        'min_cart_minor IS NOT NULL AND currency_code IS NOT NULL))',
  ];
}
