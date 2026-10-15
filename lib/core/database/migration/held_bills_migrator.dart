import 'dart:convert';

import '../../../modules/pos/models/held_bill.dart';
import '../../constants/storage_keys.dart';
import '../../identifiers/uuid_generator.dart';
import '../../services/storage/local_store.dart';
import '../axpert_database.dart';
import 'held_bill_rows.dart';
import 'settings_migrator.dart' show SettingsMigrationException;
import '../../utils/epoch_time.dart';

/// Marker row key in `migration_state`: the LocalStore to Drift copy of the
/// held bills finished at least once.
const String heldCopyMarkerKey = 'held_copy_v1';

enum HeldCopyResult { alreadyCopied, copied, recopied }

/// What the copy found (KG-125); stored in the marker row.
class HeldCopyReport {
  const HeldCopyReport({required this.duplicateRefs});

  /// Refs used by more than one held bill (ref -> count). All are imported.
  final Map<String, int> duplicateRefs;

  bool get hasFindings => duplicateRefs.isNotEmpty;

  Map<String, Object?> toJson() => {'duplicate_refs': duplicateRefs};
}

class HeldCopyOutcome {
  const HeldCopyOutcome(this.result, this.report);

  final HeldCopyResult result;

  /// Null when nothing was copied.
  final HeldCopyReport? report;
}

/// One-way copy of `axpert-held` from [LocalStore] into Drift (DEC-127), same
/// contract as `CustomersMigrator`: one transaction, read-back check at copy
/// time only, marker = "copy completed", LocalStore untouched except for
/// removing the stale key after a verified re-copy.
class HeldBillsMigrator {
  HeldBillsMigrator({required UuidGenerator uuid, DateTime Function()? now})
    : _uuid = uuid,
      _now = now ?? DateTime.now;

  final UuidGenerator _uuid;
  final DateTime Function() _now;

  Future<HeldCopyOutcome> ensureCopied(
    AxpertDatabase db,
    LocalStore store,
  ) async {
    final stale = await store.has(StorageKeys.heldDriftStale);
    final marker = await (db.select(
      db.migrationStateEntries,
    )..where((t) => t.key.equals(heldCopyMarkerKey))).getSingleOrNull();
    if (marker != null && !stale) {
      return const HeldCopyOutcome(HeldCopyResult.alreadyCopied, null);
    }

    final parsed = <HeldBill>[
      for (final bill in await _readParsed(store))
        HeldBill(
          ref: bill.ref,
          time: EpochTime.canonicalIso(bill.time),
          cart: bill.cart,
        ),
    ];
    final report = HeldCopyReport(
      duplicateRefs: HeldBillRows.duplicateRefs(parsed),
    );
    final expectedChecksum = HeldBillRows.checksum(parsed);

    await db.durableTransaction(() async {
      final now = EpochTime.fromDateTime(_now());
      await HeldBillRows.apply(db, parsed, now: now, uuid: _uuid);
      // Read-back verification (rolls the whole copy back when it fails).
      final readBack = await HeldBillRows.readList(db);
      if (readBack.length != parsed.length ||
          HeldBillRows.checksum(readBack) != expectedChecksum) {
        throw const SettingsMigrationException(
          'held bills read-back verification failed',
        );
      }
      await db
          .into(db.migrationStateEntries)
          .insertOnConflictUpdate(
            MigrationStateEntriesCompanion.insert(
              key: heldCopyMarkerKey,
              value: jsonEncode({
                'count': readBack.length,
                'checksum': expectedChecksum,
                'copied_at': EpochTime.toIso(now),
                'report': report.toJson(),
              }),
            ),
          );
    });

    if (stale) await store.remove(StorageKeys.heldDriftStale);
    return HeldCopyOutcome(
      stale || marker != null ? HeldCopyResult.recopied : HeldCopyResult.copied,
      report,
    );
  }

  /// A missing key or a non-list is the empty list, as
  /// `MockHeldBillRepository.load` returns. Every item goes through the
  /// existing `HeldBill.fromJson`, so a bad record throws a `TypeError` and
  /// nothing is written, as `load()` does today.
  Future<List<HeldBill>> _readParsed(LocalStore store) async {
    final json = await store.read(StorageKeys.held);
    if (json is! List<dynamic>) return <HeldBill>[];
    return <HeldBill>[
      for (final item in json) HeldBill.fromJson(item as Map<String, dynamic>),
    ];
  }
}
