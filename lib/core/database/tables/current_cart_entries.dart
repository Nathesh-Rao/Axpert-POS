import 'package:drift/drift.dart';

/// The current cart draft (provisional, local-only, DEC-124/130). Device-local
/// and never synced, so no sync-readiness columns and no tombstone. ONE row
/// (`id` is always 1, like `device_context_entries`): the cart is a working
/// draft replaced as a whole value by every change, never queried by field.
/// `cart_json` is the canonical `jsonEncode(cart.toJson())` (full product
/// snapshot per line); an emptied cart is stored as the empty cart JSON, as
/// the LocalStore key was.
@DataClassName('CurrentCartEntry')
class CurrentCartEntries extends Table {
  @override
  String get tableName => 'current_cart';

  // Drift's documented self-reference in `check`.
  IntColumn get id => integer()
      .withDefault(const Constant(1))
      // ignore: recursive_getters
      .check(id.equals(1))();

  TextColumn get cartJson => text()();

  /// UTC ISO 8601 text.
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
