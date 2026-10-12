import 'package:drift/drift.dart';

import 'counter_entries.dart';
import 'store_entries.dart';

/// Users (local-only, DEC-132, DEC-133). The password is never stored: only
/// `hash_algo`-hashed `salt + password`.
@DataClassName('UserEntry')
class UserEntries extends Table {
  @override
  String get tableName => 'users';

  TextColumn get id => text()();

  TextColumn get username => text().unique()();

  TextColumn get displayName => text()();

  /// `admin`, `manager` or `cashier` (stored and shown, not enforced yet).
  TextColumn get role => text()();

  TextColumn get salt => text()();

  TextColumn get passwordHash => text()();

  /// Hash scheme tag, `sha256-salted-v1`, so a stronger KDF can follow.
  TextColumn get hashAlgo => text()();

  BoolColumn get active => boolean().withDefault(const Constant(true))();

  TextColumn get createdAt => text()();

  TextColumn get updatedAt => text()();

  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Which stores and counters a user may open. A null `counter_id` means any
/// counter of the store.
@DataClassName('UserAccessEntry')
class UserAccessEntries extends Table {
  @override
  String get tableName => 'user_access';

  TextColumn get id => text()();

  TextColumn get userId => text().references(UserEntries, #id)();

  TextColumn get storeId => text().references(StoreEntries, #id)();

  TextColumn get counterId =>
      text().nullable().references(CounterEntries, #id)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
