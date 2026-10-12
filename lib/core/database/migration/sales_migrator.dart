import 'dart:convert';

import '../../../modules/sales/models/sale.dart';
import '../../constants/storage_keys.dart';
import '../../identifiers/uuid_generator.dart';
import '../../services/storage/local_store.dart';
import '../axpert_database.dart';
import 'sale_rows.dart';
import 'settings_migrator.dart' show SettingsMigrationException;

/// Marker row key in `migration_state`: the LocalStore to Drift copy of the
/// sales finished at least once.
const String salesCopyMarkerKey = 'sales_copy_v1';

enum SalesCopyResult { alreadyCopied, copied, recopied }

/// What the copy found (KG-008); stored in the marker row.
class SalesCopyReport {
  const SalesCopyReport({
    required this.duplicateNumbers,
    required this.legacyWithoutSaleId,
  });

  /// Numbers used by more than one sale (number -> count). All are imported.
  final Map<String, int> duplicateNumbers;

  /// Sales stored before `saleId` existed; each got a generated UUID.
  final int legacyWithoutSaleId;

  bool get hasFindings => duplicateNumbers.isNotEmpty;

  Map<String, Object?> toJson() => {
    'duplicate_numbers': duplicateNumbers,
    'legacy_without_sale_id': legacyWithoutSaleId,
  };
}

class SalesCopyOutcome {
  const SalesCopyOutcome(this.result, this.report);

  final SalesCopyResult result;

  /// Null when nothing was copied.
  final SalesCopyReport? report;
}

/// One-way copy of `axpert-sales` from [LocalStore] into Drift (DEC-129), same
/// contract as `HeldBillsMigrator`: one transaction, read-back check at copy
/// time only, marker = "copy completed", LocalStore untouched except for
/// removing the stale key after a verified re-copy. A duplicate non-null
/// `saleId` or a `returned` product that is not a line stops the copy before
/// anything is written (exceptions from [SaleRows.validate]).
class SalesMigrator {
  SalesMigrator({required UuidGenerator uuid, DateTime Function()? now})
    : _uuid = uuid,
      _now = now ?? DateTime.now;

  final UuidGenerator _uuid;
  final DateTime Function() _now;

  Future<SalesCopyOutcome> ensureCopied(
    AxpertDatabase db,
    LocalStore store,
  ) async {
    final stale = await store.has(StorageKeys.salesDriftStale);
    final marker = await (db.select(
      db.migrationStateEntries,
    )..where((t) => t.key.equals(salesCopyMarkerKey))).getSingleOrNull();
    if (marker != null && !stale) {
      return const SalesCopyOutcome(SalesCopyResult.alreadyCopied, null);
    }

    final parsed = await _readParsed(store);
    SaleRows.validate(parsed);
    final report = SalesCopyReport(
      duplicateNumbers: SaleRows.duplicateNumbers(parsed),
      legacyWithoutSaleId: parsed.where((s) => s.saleId == null).length,
    );
    final expectedChecksum = SaleRows.checksum(parsed);

    await db.durableTransaction(() async {
      final now = _now().toUtc().toIso8601String();
      final existing = await SaleRows.read(db);
      final plan = SaleRows.plan(parsed, existing.known, now: now, uuid: _uuid);
      await SaleRows.write(db, plan, now: now, uuid: _uuid);
      // Read-back verification (rolls the whole copy back when it fails).
      final readBack = (await SaleRows.read(db)).list;
      if (readBack.length != parsed.length ||
          SaleRows.checksum(readBack) != expectedChecksum) {
        throw const SettingsMigrationException(
          'sales read-back verification failed',
        );
      }
      await db
          .into(db.migrationStateEntries)
          .insertOnConflictUpdate(
            MigrationStateEntriesCompanion.insert(
              key: salesCopyMarkerKey,
              value: jsonEncode({
                'count': readBack.length,
                'checksum': expectedChecksum,
                'copied_at': now,
                'report': report.toJson(),
              }),
            ),
          );
    });

    if (stale) await store.remove(StorageKeys.salesDriftStale);
    return SalesCopyOutcome(
      stale || marker != null
          ? SalesCopyResult.recopied
          : SalesCopyResult.copied,
      report,
    );
  }

  /// A missing key or a non-list is the empty list, as
  /// `MockSaleRepository.load` returns. Every item goes through the existing
  /// `Sale.fromJson`, so a bad record throws a `TypeError` and nothing is
  /// written, as `load()` does today.
  Future<List<Sale>> _readParsed(LocalStore store) async {
    final json = await store.read(StorageKeys.sales);
    if (json is! List<dynamic>) return <Sale>[];
    return <Sale>[
      for (final item in json) Sale.fromJson(item as Map<String, dynamic>),
    ];
  }
}
