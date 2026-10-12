import 'dart:convert';

import '../../../modules/pos/models/cart.dart';
import '../../constants/storage_keys.dart';
import '../../services/storage/local_store.dart';
import '../axpert_database.dart';
import 'cart_rows.dart';
import 'settings_migrator.dart' show SettingsMigrationException;

/// Marker row key in `migration_state`: the LocalStore to Drift copy of the
/// cart finished at least once.
const String cartCopyMarkerKey = 'cart_copy_v1';

enum CartCopyResult { alreadyCopied, copied, recopied }

/// What the copy found; stored in the marker row.
class CartCopyReport {
  const CartCopyReport({required this.hadValue, required this.unreadable});

  /// `axpert-cart` held a value.
  final bool hadValue;

  /// The value could not be read as a cart; the cart is empty, as the
  /// LocalStore path resets it silently.
  final bool unreadable;

  bool get hasFindings => unreadable;

  Map<String, Object?> toJson() => {
    'had_value': hadValue,
    'unreadable': unreadable,
  };
}

class CartCopyOutcome {
  const CartCopyOutcome(this.result, this.report);

  final CartCopyResult result;

  /// Null when nothing was copied.
  final CartCopyReport? report;
}

/// One-way copy of `axpert-cart` from [LocalStore] into Drift (DEC-130), same
/// contract as the other migrators: one transaction, read-back check at copy
/// time only, marker = "copy completed", LocalStore untouched except for
/// removing the stale key after a verified re-copy.
///
/// After the copy the Drift cart equals what `MockCartRepository.load` returns
/// from LocalStore: a readable cart is copied; a missing or UNREADABLE value
/// copies nothing (absence = the empty cart) and never throws. On a stale
/// re-copy an existing row is reset to the empty cart in that case.
class CartMigrator {
  CartMigrator({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  Future<CartCopyOutcome> ensureCopied(
    AxpertDatabase db,
    LocalStore store,
  ) async {
    final stale = await store.has(StorageKeys.cartDriftStale);
    final marker = await (db.select(
      db.migrationStateEntries,
    )..where((t) => t.key.equals(cartCopyMarkerKey))).getSingleOrNull();
    if (marker != null && !stale) {
      return const CartCopyOutcome(CartCopyResult.alreadyCopied, null);
    }

    final raw = await store.read(StorageKeys.cart);
    Cart? parsed;
    if (raw is Map<String, dynamic>) {
      try {
        parsed = Cart.fromJson(raw);
      } on Object {
        parsed = null;
      }
    }
    final report = CartCopyReport(
      hadValue: raw != null,
      unreadable: raw != null && parsed == null,
    );
    final expected = parsed ?? Cart.empty;

    await db.durableTransaction(() async {
      final now = _now().toUtc().toIso8601String();
      final existing = await CartRows.read(db);
      final hasRow = existing.unreadable || existing.json != null;
      if (parsed != null) {
        await CartRows.write(db, CartRows.encode(parsed), now: now);
      } else if (hasRow) {
        await CartRows.write(db, CartRows.encode(Cart.empty), now: now);
      }
      // Read-back verification (rolls the whole copy back when it fails).
      final readBack = await CartRows.read(db);
      if (readBack.unreadable ||
          CartRows.encode(readBack.cart) != CartRows.encode(expected)) {
        throw const SettingsMigrationException(
          'cart read-back verification failed',
        );
      }
      await db
          .into(db.migrationStateEntries)
          .insertOnConflictUpdate(
            MigrationStateEntriesCompanion.insert(
              key: cartCopyMarkerKey,
              value: jsonEncode({
                'count': parsed != null ? 1 : 0,
                'checksum': CartRows.checksum(expected),
                'copied_at': now,
                'report': report.toJson(),
              }),
            ),
          );
    });

    if (stale) await store.remove(StorageKeys.cartDriftStale);
    return CartCopyOutcome(
      stale || marker != null ? CartCopyResult.recopied : CartCopyResult.copied,
      report,
    );
  }
}
