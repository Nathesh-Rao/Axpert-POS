import 'dart:convert';

import '../../../features/products/domain/entities/product.dart';
import '../../constants/storage_keys.dart';
import '../../identifiers/uuid_generator.dart';
import '../../services/storage/local_store.dart';
import '../axpert_database.dart';
import 'product_rows.dart';
import 'settings_migrator.dart' show SettingsMigrationException;
import '../../utils/epoch_time.dart';

/// Marker row key in `migration_state`: the LocalStore to Drift copy of the
/// products finished at least once.
const String productsCopyMarkerKey = 'products_copy_v1';

enum ProductsCopyResult { alreadyCopied, copied, recopied }

/// What the copy found; stored in the marker row. Duplicate codes and
/// barcodes are only reported (axpert A3 is open); duplicate ids stop the copy.
class ProductsCopyReport {
  const ProductsCopyReport({
    required this.duplicateCodes,
    required this.duplicateBarcodes,
  });

  final Map<String, List<int>> duplicateCodes;
  final Map<String, List<int>> duplicateBarcodes;

  bool get hasFindings =>
      duplicateCodes.isNotEmpty || duplicateBarcodes.isNotEmpty;

  Map<String, Object?> toJson() => {
    'duplicate_codes': duplicateCodes,
    'duplicate_barcodes': duplicateBarcodes,
  };
}

class ProductsCopyOutcome {
  const ProductsCopyOutcome(this.result, this.report);

  final ProductsCopyResult result;

  /// Null when nothing was copied.
  final ProductsCopyReport? report;
}

/// One-way copy of `axpert-products` from [LocalStore] into Drift (DEC-128),
/// same contract as the other migrators: one transaction, read-back check at
/// copy time only, marker = "copy completed", LocalStore untouched except for
/// removing the stale key after a verified re-copy. Duplicate integer ids
/// stop the copy before anything is written ([DuplicateProductIdsException]).
class ProductsMigrator {
  ProductsMigrator({required UuidGenerator uuid, DateTime Function()? now})
    : _uuid = uuid,
      _now = now ?? DateTime.now;

  final UuidGenerator _uuid;
  final DateTime Function() _now;

  Future<ProductsCopyOutcome> ensureCopied(
    AxpertDatabase db,
    LocalStore store,
  ) async {
    final stale = await store.has(StorageKeys.productsDriftStale);
    final marker = await (db.select(
      db.migrationStateEntries,
    )..where((t) => t.key.equals(productsCopyMarkerKey))).getSingleOrNull();
    if (marker != null && !stale) {
      return const ProductsCopyOutcome(ProductsCopyResult.alreadyCopied, null);
    }

    final parsed = await _readParsed(store);
    final dups = ProductRows.duplicateIds(parsed);
    if (dups.isNotEmpty) throw DuplicateProductIdsException(dups);
    final report = ProductsCopyReport(
      duplicateCodes: ProductRows.duplicateCodes(parsed),
      duplicateBarcodes: ProductRows.duplicateBarcodes(parsed),
    );
    final expectedChecksum = ProductRows.checksum(parsed);

    await db.durableTransaction(() async {
      final now = EpochTime.fromDateTime(_now());
      final current = await ProductRows.read(db);
      final plan = ProductRows.plan(
        parsed,
        current.known,
        now: now,
        uuid: _uuid,
      );
      await ProductRows.write(db, plan, now: now);
      // Read-back verification (rolls the whole copy back when it fails).
      final readBack = (await ProductRows.read(db)).list;
      if (readBack.length != parsed.length ||
          ProductRows.checksum(readBack) != expectedChecksum) {
        throw const SettingsMigrationException(
          'products read-back verification failed',
        );
      }
      await db
          .into(db.migrationStateEntries)
          .insertOnConflictUpdate(
            MigrationStateEntriesCompanion.insert(
              key: productsCopyMarkerKey,
              value: jsonEncode({
                'count': readBack.length,
                'checksum': expectedChecksum,
                'copied_at': EpochTime.toIso(now),
                'report': report.toJson(),
              }),
            ),
          );
    });

    if (stale) await store.remove(StorageKeys.productsDriftStale);
    return ProductsCopyOutcome(
      stale || marker != null
          ? ProductsCopyResult.recopied
          : ProductsCopyResult.copied,
      report,
    );
  }

  /// A missing key is an empty list (no demo data in the app, DEC-135). Every
  /// item goes through the existing
  /// `Product.fromJson`, so a bad record throws a `TypeError` and nothing is
  /// written, as `load()` does today.
  Future<List<Product>> _readParsed(LocalStore store) async {
    if (!await store.has(StorageKeys.products)) return const <Product>[];
    final json = await store.read(StorageKeys.products);
    return <Product>[
      for (final item in json as List<dynamic>)
        Product.fromJson(item as Map<String, dynamic>),
    ];
  }
}
