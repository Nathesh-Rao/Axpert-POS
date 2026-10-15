import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../modules/pos/models/cart.dart';
import '../../../modules/pos/models/held_bill.dart';
import '../../identifiers/uuid_generator.dart';
import '../../services/pricing/currency.dart';
import '../../services/pricing/currency_registry.dart';
import '../axpert_database.dart';
import 'fnv1a.dart';
import '../../utils/epoch_time.dart';

/// Held list <-> `held_bills` table mapping shared by the one-way copy and
/// every save (DEC-127). Callers wrap [apply] in `durableTransaction`.
abstract final class HeldBillRows {
  /// Refs used by more than one bill (ref -> count). Reported, never fixed:
  /// the table keeps every bill and `ref` is not unique (KG-125).
  static Map<String, int> duplicateRefs(List<HeldBill> list) {
    final counts = <String, int>{};
    for (final bill in list) {
      counts[bill.ref] = (counts[bill.ref] ?? 0) + 1;
    }
    counts.removeWhere((_, n) => n < 2);
    return counts;
  }

  static String cartJson(HeldBill bill) => jsonEncode(bill.cart.toJson());

  /// Makes the table equal [list]: the k-th occurrence of a ref matches the
  /// k-th ACTIVE row with that ref (by position), keeping its UUID and
  /// `created_at`; new bills get a new UUID; active rows that left the list
  /// get `deleted_at` (never DELETE); `position` is the list index.
  static Future<void> apply(
    AxpertDatabase db,
    List<HeldBill> list, {
    required int now,
    required UuidGenerator uuid,
    String? storeId,
  }) async {
    final active =
        await (db.select(db.heldBillEntries)
              ..where(
                (t) => storeId == null
                    ? t.deletedAt.isNull()
                    : t.deletedAt.isNull() & t.storeId.equals(storeId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    final pool = <String, List<HeldBillEntry>>{};
    for (final row in active) {
      pool.putIfAbsent(row.ref, () => <HeldBillEntry>[]).add(row);
    }
    final matched = <String>{};
    final seen = <String, int>{};
    for (var i = 0; i < list.length; i++) {
      final bill = list[i];
      final k = seen[bill.ref] = (seen[bill.ref] ?? -1) + 1;
      final candidates = pool[bill.ref];
      final row = candidates != null && k < candidates.length
          ? candidates[k]
          : null;
      final json = cartJson(bill);
      if (row == null) {
        await db
            .into(db.heldBillEntries)
            .insert(
              HeldBillEntriesCompanion.insert(
                id: uuid.generate(),
                ref: bill.ref,
                position: i,
                heldAt: EpochTime.parseOrZero(bill.time),
                cartJson: json,
                createdAt: now,
                updatedAt: now,
                storeId: Value(storeId),
              ),
            );
        continue;
      }
      matched.add(row.id);
      if (row.position == i &&
          row.heldAt == EpochTime.parseOrZero(bill.time) &&
          row.cartJson == json) {
        continue;
      }
      await (db.update(
        db.heldBillEntries,
      )..where((t) => t.id.equals(row.id))).write(
        HeldBillEntriesCompanion(
          position: Value(i),
          heldAt: Value(EpochTime.parseOrZero(bill.time)),
          cartJson: Value(json),
          updatedAt: Value(now),
        ),
      );
    }
    for (final row in active) {
      if (matched.contains(row.id)) continue;
      await (db.update(
        db.heldBillEntries,
      )..where((t) => t.id.equals(row.id))).write(
        HeldBillEntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
    }
  }

  /// Active rows in list order.
  static Future<List<HeldBill>> readList(
    AxpertDatabase db, {
    String? storeId,
    Currency currency = CurrencyRegistry.inr,
  }) async {
    final rows =
        await (db.select(db.heldBillEntries)
              ..where(
                (t) => storeId == null
                    ? t.deletedAt.isNull()
                    : t.deletedAt.isNull() & t.storeId.equals(storeId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return [
      for (final r in rows)
        HeldBill(
          ref: r.ref,
          time: EpochTime.toIso(r.heldAt),
          cart: Cart.fromJson(
            jsonDecode(r.cartJson) as Map<String, dynamic>,
            currency: currency,
          ),
        ),
    ];
  }

  /// FNV-1a over the canonical JSON lines of [list], in order.
  static String checksum(List<HeldBill> list) =>
      fnv1a32Hex(list.map((b) => jsonEncode(b.toJson())).join('\n'));
}
