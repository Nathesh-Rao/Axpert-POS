import '../../../../core/bindings/startup_diagnostics.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/database/axpert_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/migration/product_rows.dart';
import '../../../../core/database/migration/products_migrator.dart';
import '../../../../core/identifiers/uuid_generator.dart';
import '../../../../core/services/storage/local_store.dart';
import '../../../../core/utils/serial_queue.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import 'mock_product_repository.dart';

/// Products in Drift (source of truth), dual-written to [LocalStore] so the
/// rollback to the LocalStore backend loses nothing (DEC-128).
///
/// The controller's in-memory list stays authoritative in the session: this
/// class only persists what it is given. A save diffs the list against an
/// in-memory snapshot of the table and writes only the changed rows; the
/// snapshot is replaced only after the transaction committed, so a failed save
/// leaves it as it was. When Drift cannot be used (open, copy or write
/// failure) the session falls back to LocalStore and sets the stale key, so the
/// next start re-copies LocalStore into Drift first.
class DriftProductRepository implements ProductRepository {
  DriftProductRepository({
    required DatabaseProvider provider,
    required LocalStore store,
    required StartupDiagnostics diagnostics,
    required UuidGenerator uuid,
    ProductsMigrator? migrator,
    DateTime Function()? now,
  }) : _provider = provider,
       _store = store,
       _diagnostics = diagnostics,
       _uuid = uuid,
       _migrator = migrator ?? ProductsMigrator(uuid: uuid, now: now),
       _now = now ?? DateTime.now,
       _fallback = MockProductRepository(store);

  final DatabaseProvider _provider;
  final LocalStore _store;
  final StartupDiagnostics _diagnostics;
  final UuidGenerator _uuid;
  final ProductsMigrator _migrator;
  final DateTime Function() _now;
  final MockProductRepository _fallback;

  /// Null until Drift loaded successfully, and again after a failure.
  AxpertDatabase? _db;

  /// What the table holds, by legacy id; rebuilt from the rows at every load
  /// (so after a copy or a stale re-copy) and replaced after a committed save.
  Map<int, KnownProduct> _known = <int, KnownProduct>{};

  /// The snapshot, for tests.
  Map<int, KnownProduct> get snapshot => _known;

  @override
  Future<List<Product>> load() async {
    try {
      final db = await _provider.open();
      final outcome = await _migrator.ensureCopied(db, _store);
      final report = outcome.report;
      if (report != null && report.hasFindings) {
        _diagnostics.record(
          'products copy report',
          report.toJson(),
          StackTrace.empty,
        );
      }
      final read = await ProductRows.read(db);
      _known = read.known;
      _db = db;
      return read.list;
    } on DuplicateProductIdsException catch (error, stackTrace) {
      // Loud, and nothing was written: LocalStore stays authoritative.
      await _degrade('products duplicate ids', error, stackTrace);
      return _fallback.load();
    } on Object catch (error, stackTrace) {
      await _degrade('products load', error, stackTrace);
      return _fallback.load();
    }
  }

  /// Saves run one after another (see [SerialQueue], KG-190).
  final SerialQueue _saves = SerialQueue();

  @override
  Future<void> save(List<Product> products) =>
      _saves.run(() => _save(products));

  Future<void> _save(List<Product> products) async {
    final db = _db;
    if (db == null) {
      await _markStale();
      return _fallback.save(products);
    }
    try {
      final now = _now().toUtc().toIso8601String();
      final plan = ProductRows.plan(products, _known, now: now, uuid: _uuid);
      if (!plan.isEmpty) {
        await db.durableTransaction(
          () => ProductRows.write(db, plan, now: now),
        );
      }
      // Only after the commit: a failed write leaves the snapshot unchanged.
      _known = plan.next;
    } on Object catch (error, stackTrace) {
      await _degrade('products save', error, stackTrace);
      return _fallback.save(products);
    }
    try {
      await _store.write(StorageKeys.products, <Map<String, dynamic>>[
        for (final p in products) p.toJson(),
      ]);
    } on Object catch (error, stackTrace) {
      // Drift is already saved; only the rollback copy is behind.
      _diagnostics.record('products dual-write', error, stackTrace);
    }
  }

  Future<void> _degrade(String stage, Object error, StackTrace stackTrace) {
    _db = null;
    _diagnostics.record(stage, error, stackTrace);
    return _markStale();
  }

  Future<void> _markStale() async {
    try {
      await _store.write(StorageKeys.productsDriftStale, true);
    } on Object catch (error, stackTrace) {
      _diagnostics.record('products stale marker', error, stackTrace);
    }
  }
}

/// The rollback backend: LocalStore only. Every session marks Drift stale, so
/// switching back to Drift re-copies first (DEC-128).
class LocalStoreProductRepository implements ProductRepository {
  LocalStoreProductRepository(this._store)
    : _inner = MockProductRepository(_store);

  final LocalStore _store;
  final MockProductRepository _inner;

  @override
  Future<List<Product>> load() async {
    await _store.write(StorageKeys.productsDriftStale, true);
    return _inner.load();
  }

  @override
  Future<void> save(List<Product> products) async {
    await _store.write(StorageKeys.productsDriftStale, true);
    return _inner.save(products);
  }
}
