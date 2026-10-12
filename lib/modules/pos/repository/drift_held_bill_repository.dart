import '../../../core/bindings/startup_diagnostics.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/database/axpert_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/migration/held_bill_rows.dart';
import '../../../core/database/migration/held_bills_migrator.dart';
import '../../../core/identifiers/uuid_generator.dart';
import '../../../core/services/storage/local_store.dart';
import '../../../core/utils/serial_queue.dart';
import '../models/held_bill.dart';
import 'held_bill_repository.dart';
import 'mock_held_bill_repository.dart';

/// Held bills in Drift (source of truth), dual-written to [LocalStore] so the
/// rollback to the LocalStore backend loses nothing (DEC-127).
///
/// The controller's in-memory list stays authoritative in the session: this
/// class only persists what it is given. When Drift cannot be used (open,
/// copy or write failure) the session falls back to LocalStore and sets the
/// stale key, so the next start re-copies LocalStore into Drift first.
class DriftHeldBillRepository implements HeldBillRepository {
  DriftHeldBillRepository({
    required DatabaseProvider provider,
    required LocalStore store,
    required StartupDiagnostics diagnostics,
    required UuidGenerator uuid,
    HeldBillsMigrator? migrator,
    DateTime Function()? now,
  }) : _provider = provider,
       _store = store,
       _diagnostics = diagnostics,
       _uuid = uuid,
       _migrator = migrator ?? HeldBillsMigrator(uuid: uuid, now: now),
       _now = now ?? DateTime.now,
       _fallback = MockHeldBillRepository(store);

  final DatabaseProvider _provider;
  final LocalStore _store;
  final StartupDiagnostics _diagnostics;
  final UuidGenerator _uuid;
  final HeldBillsMigrator _migrator;
  final DateTime Function() _now;
  final MockHeldBillRepository _fallback;

  /// Null until Drift loaded successfully, and again after a failure.
  AxpertDatabase? _db;

  @override
  Future<List<HeldBill>> load() async {
    try {
      final db = await _provider.open();
      final outcome = await _migrator.ensureCopied(db, _store);
      final report = outcome.report;
      if (report != null && report.hasFindings) {
        _diagnostics.record(
          'held copy report',
          report.toJson(),
          StackTrace.empty,
        );
      }
      final list = await HeldBillRows.readList(db);
      _db = db;
      return list;
    } on Object catch (error, stackTrace) {
      await _degrade('held load', error, stackTrace);
      return _fallback.load();
    }
  }

  /// Saves run one after another (see [SerialQueue], KG-190).
  final SerialQueue _saves = SerialQueue();

  @override
  Future<void> save(List<HeldBill> bills) => _saves.run(() => _save(bills));

  Future<void> _save(List<HeldBill> bills) async {
    final db = _db;
    if (db == null) {
      await _markStale();
      return _fallback.save(bills);
    }
    try {
      final now = _now().toUtc().toIso8601String();
      await db.durableTransaction(
        () => HeldBillRows.apply(db, bills, now: now, uuid: _uuid),
      );
    } on Object catch (error, stackTrace) {
      await _degrade('held save', error, stackTrace);
      return _fallback.save(bills);
    }
    try {
      await _store.write(StorageKeys.held, <Map<String, dynamic>>[
        for (final b in bills) b.toJson(),
      ]);
    } on Object catch (error, stackTrace) {
      // Drift is already saved; only the rollback copy is behind.
      _diagnostics.record('held dual-write', error, stackTrace);
    }
  }

  Future<void> _degrade(String stage, Object error, StackTrace stackTrace) {
    _db = null;
    _diagnostics.record(stage, error, stackTrace);
    return _markStale();
  }

  Future<void> _markStale() async {
    try {
      await _store.write(StorageKeys.heldDriftStale, true);
    } on Object catch (error, stackTrace) {
      _diagnostics.record('held stale marker', error, stackTrace);
    }
  }
}

/// The rollback backend: LocalStore only. Every session marks Drift stale, so
/// switching back to Drift re-copies first (DEC-127).
class LocalStoreHeldBillRepository implements HeldBillRepository {
  LocalStoreHeldBillRepository(this._store)
    : _inner = MockHeldBillRepository(_store);

  final LocalStore _store;
  final MockHeldBillRepository _inner;

  @override
  Future<List<HeldBill>> load() async {
    await _store.write(StorageKeys.heldDriftStale, true);
    return _inner.load();
  }

  @override
  Future<void> save(List<HeldBill> bills) async {
    await _store.write(StorageKeys.heldDriftStale, true);
    return _inner.save(bills);
  }
}
