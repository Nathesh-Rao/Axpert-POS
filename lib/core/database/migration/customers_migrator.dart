import 'dart:convert';

import '../../../modules/customers/models/customer.dart';
import '../../constants/storage_keys.dart';
import '../../identifiers/uuid_generator.dart';
import '../../services/storage/local_store.dart';
import '../axpert_database.dart';
import 'customer_rows.dart';
import 'settings_migrator.dart' show SettingsMigrationException;
import '../../utils/epoch_time.dart';

/// Marker row key in `migration_state`: the LocalStore to Drift copy of the
/// customers finished at least once.
const String customersCopyMarkerKey = 'customers_copy_v1';

enum CustomersCopyResult { alreadyCopied, copied, recopied }

/// What the copy found (KG-132); stored in the marker row.
class CustomersCopyReport {
  const CustomersCopyReport({
    required this.renamed,
    required this.duplicateMembers,
    required this.salesChecked,
    required this.salesNameUnmatched,
    required this.salesNameAmbiguous,
  });

  final List<RenamedCustomerId> renamed;

  /// Member numbers used by more than one customer (member -> legacy ids).
  final Map<String, List<String>> duplicateMembers;

  /// Read-only scan of `axpert-sales`: sales whose customer NAME matches no
  /// customer / more than one customer. Sales are never changed.
  final int salesChecked;
  final int salesNameUnmatched;
  final int salesNameAmbiguous;

  bool get hasFindings =>
      renamed.isNotEmpty ||
      duplicateMembers.isNotEmpty ||
      salesNameUnmatched > 0 ||
      salesNameAmbiguous > 0;

  Map<String, Object?> toJson() => {
    'renamed': [for (final r in renamed) r.toJson()],
    'duplicate_members': duplicateMembers,
    'sales_checked': salesChecked,
    'sales_name_unmatched': salesNameUnmatched,
    'sales_name_ambiguous': salesNameAmbiguous,
  };
}

class CustomersCopyOutcome {
  const CustomersCopyOutcome(this.result, this.report);

  final CustomersCopyResult result;

  /// Null when nothing was copied.
  final CustomersCopyReport? report;
}

/// One-way copy of `axpert-customers` from [LocalStore] into Drift (DEC-126),
/// same contract as `SettingsMigrator`: one transaction, read-back check at
/// copy time only, marker = "copy completed", LocalStore untouched except for
/// removing the stale key after a verified re-copy.
class CustomersMigrator {
  CustomersMigrator({required UuidGenerator uuid, DateTime Function()? now})
    : _uuid = uuid,
      _now = now ?? DateTime.now;

  final UuidGenerator _uuid;
  final DateTime Function() _now;

  Future<CustomersCopyOutcome> ensureCopied(
    AxpertDatabase db,
    LocalStore store,
  ) async {
    final stale = await store.has(StorageKeys.customersDriftStale);
    final marker = await (db.select(
      db.migrationStateEntries,
    )..where((t) => t.key.equals(customersCopyMarkerKey))).getSingleOrNull();
    if (marker != null && !stale) {
      return const CustomersCopyOutcome(
        CustomersCopyResult.alreadyCopied,
        null,
      );
    }

    final parsed = await _readParsed(store);
    final normalized = CustomerRows.normalize(parsed);
    final report = await _report(store, normalized);
    final expectedChecksum = CustomerRows.checksum(normalized.customers);

    await db.durableTransaction(() async {
      final now = EpochTime.fromDateTime(_now());
      await CustomerRows.apply(db, normalized.customers, now: now, uuid: _uuid);
      // Read-back verification (rolls the whole copy back when it fails).
      final readBack = await CustomerRows.readList(db);
      if (readBack.length != normalized.customers.length ||
          CustomerRows.checksum(readBack) != expectedChecksum) {
        throw const SettingsMigrationException(
          'customers read-back verification failed',
        );
      }
      await db
          .into(db.migrationStateEntries)
          .insertOnConflictUpdate(
            MigrationStateEntriesCompanion.insert(
              key: customersCopyMarkerKey,
              value: jsonEncode({
                'count': readBack.length,
                'checksum': expectedChecksum,
                'copied_at': EpochTime.toIso(now),
                'report': report.toJson(),
              }),
            ),
          );
    });

    if (stale) await store.remove(StorageKeys.customersDriftStale);
    return CustomersCopyOutcome(
      stale || marker != null
          ? CustomersCopyResult.recopied
          : CustomersCopyResult.copied,
      report,
    );
  }

  /// A missing key is an empty list (no demo data in the app, DEC-135). Every item goes through the existing
  /// `Customer.fromJson`, so a bad record throws a `TypeError` and nothing is
  /// written, as `load()` does today.
  Future<List<Customer>> _readParsed(LocalStore store) async {
    if (!await store.has(StorageKeys.customers)) {
      return const <Customer>[];
    }
    final json = await store.read(StorageKeys.customers);
    return <Customer>[
      for (final item in json as List<dynamic>)
        Customer.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<CustomersCopyReport> _report(
    LocalStore store,
    NormalizedCustomers normalized,
  ) async {
    final byMember = <String, List<String>>{};
    final namesCount = <String, int>{};
    for (final c in normalized.customers) {
      if (c.member.isNotEmpty) {
        byMember.putIfAbsent(c.member, () => <String>[]).add(c.id);
      }
      namesCount[c.name] = (namesCount[c.name] ?? 0) + 1;
    }
    byMember.removeWhere((_, ids) => ids.length < 2);

    var checked = 0, unmatched = 0, ambiguous = 0;
    final sales = await store.has(StorageKeys.sales)
        ? await store.read(StorageKeys.sales)
        : null;
    if (sales is List<dynamic>) {
      for (final sale in sales) {
        if (sale is! Map<String, dynamic> || sale['customer'] is! String) {
          continue;
        }
        checked++;
        final matches = namesCount[sale['customer'] as String] ?? 0;
        if (matches == 0) unmatched++;
        if (matches > 1) ambiguous++;
      }
    }
    return CustomersCopyReport(
      renamed: normalized.renamed,
      duplicateMembers: byMember,
      salesChecked: checked,
      salesNameUnmatched: unmatched,
      salesNameAmbiguous: ambiguous,
    );
  }
}
