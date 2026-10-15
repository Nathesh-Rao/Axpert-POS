import '../../../core/bindings/startup_diagnostics.dart';
import '../../../core/bindings/startup_timeline.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/database/axpert_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/migration/sale_rows.dart';
import '../../../core/database/migration/sales_migrator.dart';
import '../../../core/identifiers/uuid_generator.dart';
import '../../../core/services/storage/local_store.dart';
import '../../../core/session/store_scope.dart';
import '../../../core/utils/serial_queue.dart';
import '../models/sale.dart';
import 'mock_sale_repository.dart';
import 'sale_repository.dart';
import '../../../core/utils/epoch_time.dart';

/// Sales in Drift (source of truth), dual-written to [LocalStore] in the old
/// `axpert-sales` shape so the rollback to the LocalStore backend loses
/// nothing (DEC-129).
///
/// The controller's in-memory list stays authoritative in the session: this
/// class only persists what it is given. A save diffs the list against an
/// in-memory snapshot of the table and writes only appended sales and changed
/// `returned` quantities; the snapshot is replaced only after the transaction
/// committed. When Drift cannot be used (open, copy or write failure) the
/// session falls back to LocalStore and sets the stale key, so the next start
/// re-copies LocalStore into Drift first.
///
/// The checkout and refund transactions (`DriftLedgerRepository`) use the
/// staging methods below to write sales together with stock and points.
class DriftSaleRepository implements SaleRepository {
  DriftSaleRepository({
    required DatabaseProvider provider,
    required LocalStore store,
    required StartupDiagnostics diagnostics,
    required UuidGenerator uuid,
    SerialQueue? queue,
    StoreScope? scope,
    SalesMigrator? migrator,
    DateTime Function()? now,
  }) : _provider = provider,
       _store = store,
       _diagnostics = diagnostics,
       _uuid = uuid,
       _saves = queue ?? SerialQueue(),
       _scope = scope ?? StoreScope(),
       _migrator = migrator ?? SalesMigrator(uuid: uuid, now: now),
       _now = now ?? DateTime.now,
       _fallback = MockSaleRepository(store);

  final DatabaseProvider _provider;
  final LocalStore _store;
  final StartupDiagnostics _diagnostics;
  final UuidGenerator _uuid;
  final SerialQueue _saves;
  final SalesMigrator _migrator;
  final DateTime Function() _now;
  final MockSaleRepository _fallback;

  /// See DriftProductRepository: scoped mode filters by store and stamps the
  /// session on new rows, has no LocalStore mirror and no fallback.
  final StoreScope _scope;

  /// The scope the rows are stamped with (the ledger writes through it).
  StoreScope get scope => _scope;

  /// Null until Drift loaded successfully, and again after a failure.
  AxpertDatabase? _db;

  /// What the table holds, by identity key; rebuilt from the rows at every
  /// load and replaced after a committed write.
  Map<String, KnownSale> _known = <String, KnownSale>{};

  /// The snapshot, for tests.
  Map<String, KnownSale> get snapshot => _known;

  /// The open database, or null when this session is on the LocalStore path.
  AxpertDatabase? get database => _db;

  @override
  Future<List<Sale>> load() async {
    try {
      final db = await _provider.open();
      if (!_scope.scoped) {
        final outcome = await StartupTimeline.measure(
          'sales drift copy',
          () => _migrator.ensureCopied(db, _store),
        );
        final report = outcome.report;
        if (report != null && report.hasFindings) {
          _diagnostics.record(
            'sales copy report',
            report.toJson(),
            StackTrace.empty,
          );
        }
      }
      try {
        await SaleRows.resolveLinks(db);
      } on Object catch (error, stackTrace) {
        // Derived data only: the next start tries again.
        _diagnostics.record('sales link backfill', error, stackTrace);
      }
      final read = await StartupTimeline.measure(
        'sales drift read',
        () => SaleRows.read(db, storeId: _scope.storeId),
      );
      _known = read.known;
      _db = db;
      return read.list;
    } on DuplicateSaleIdsException catch (error, stackTrace) {
      if (_scope.scoped) rethrow;
      await degrade('sales duplicate sale ids', error, stackTrace);
      return _fallback.load();
    } on OrphanReturnedException catch (error, stackTrace) {
      if (_scope.scoped) rethrow;
      await degrade('sales orphan returned', error, stackTrace);
      return _fallback.load();
    } on Object catch (error, stackTrace) {
      if (_scope.scoped) rethrow;
      await degrade('sales load', error, stackTrace);
      return _fallback.load();
    }
  }

  @override
  Future<void> save(List<Sale> sales) => _saves.run(() => _save(sales));

  Future<void> _save(List<Sale> sales) async {
    final db = _db;
    if (db == null) {
      if (_scope.scoped) throw StateError('Sales are not loaded');
      await markStale();
      return _fallback.save(sales);
    }
    try {
      final now = EpochTime.fromDateTime(_now());
      final plan = SaleRows.plan(sales, _known, now: now, uuid: _uuid);
      if (!plan.isEmpty) {
        await StartupTimeline.logged(
          'sales save drift (${plan.rowCount} rows)',
          () => db.durableTransaction(
            () =>
                SaleRows.write(db, plan, now: now, uuid: _uuid, scope: _scope),
          ),
        );
      }
      // Only after the commit: a failed write leaves the snapshot unchanged.
      _known = plan.next;
    } on Object catch (error, stackTrace) {
      if (_scope.scoped) rethrow;
      await degrade('sales save', error, stackTrace);
      return _fallback.save(sales);
    }
    await mirror(sales);
  }

  // ---- participation in the checkout and refund transactions ----

  /// Plans the writes for [sales] against the current snapshot (no database
  /// access). The caller writes the plan inside its own transaction and calls
  /// [adopt] after the commit.
  SaleWrite stage(List<Sale> sales, {required int now}) =>
      SaleRows.plan(sales, _known, now: now, uuid: _uuid);

  /// Replaces the snapshot after the caller's transaction committed.
  void adopt(SaleWrite plan) => _known = plan.next;

  /// A save without the queue, for callers that already run inside it.
  Future<void> saveNow(List<Sale> sales) => _save(sales);

  /// Writes the LocalStore copy (the rollback mirror).
  Future<void> mirror(List<Sale> sales) async {
    if (_scope.scoped) return;
    try {
      await StartupTimeline.logged(
        'sales save mirror',
        () => _store.write(StorageKeys.sales, <Map<String, dynamic>>[
          for (final s in sales) s.toJson(),
        ]),
      );
    } on Object catch (error, stackTrace) {
      // Drift is already saved; only the rollback copy is behind.
      _diagnostics.record('sales dual-write', error, stackTrace);
    }
  }

  /// The LocalStore-only save used after a failure (Mock path, with its
  /// delay), as the other repositories do.
  Future<void> saveFallback(List<Sale> sales) => _fallback.save(sales);

  /// Leaves Drift for the rest of the session and marks it stale.
  Future<void> degrade(String stage, Object error, StackTrace stackTrace) {
    _db = null;
    _diagnostics.record(stage, error, stackTrace);
    return markStale();
  }

  Future<void> markStale() async {
    try {
      await _store.write(StorageKeys.salesDriftStale, true);
    } on Object catch (error, stackTrace) {
      _diagnostics.record('sales stale marker', error, stackTrace);
    }
  }
}

/// The rollback backend: LocalStore only. Every session marks Drift stale, so
/// switching back to Drift re-copies first (DEC-129).
class LocalStoreSaleRepository implements SaleRepository {
  LocalStoreSaleRepository(this._store) : _inner = MockSaleRepository(_store);

  final LocalStore _store;
  final MockSaleRepository _inner;

  @override
  Future<List<Sale>> load() async {
    await _store.write(StorageKeys.salesDriftStale, true);
    return _inner.load();
  }

  @override
  Future<void> save(List<Sale> sales) async {
    await _store.write(StorageKeys.salesDriftStale, true);
    return _inner.save(sales);
  }
}
