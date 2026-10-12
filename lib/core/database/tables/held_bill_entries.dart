import 'package:drift/drift.dart';

/// Held bills (provisional, local-only, DEC-124/127). Device-local and never
/// synced, so there are no sync-readiness columns. `ref` is the app's
/// `HeldBill.ref` and is NOT unique (KG-125); `id` is the UUID v4 identity.
@DataClassName('HeldBillEntry')
class HeldBillEntries extends Table {
  @override
  String get tableName => 'held_bills';

  TextColumn get id => text()();

  TextColumn get ref => text()();

  /// Index in the app's held list (oldest first; the order is observable).
  IntColumn get position => integer()();

  /// `HeldBill.time` verbatim (ISO text in the app, never parsed here).
  TextColumn get heldAt => text()();

  /// Canonical JSON of the cart snapshot (full product snapshot per line).
  TextColumn get cartJson => text()();

  /// UTC ISO 8601 text.
  TextColumn get createdAt => text()();

  TextColumn get updatedAt => text()();

  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
