import '../../../core/bindings/startup_diagnostics.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/database/axpert_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/migration/customer_rows.dart';
import '../../../core/database/migration/customers_migrator.dart';
import '../../../core/identifiers/uuid_generator.dart';
import '../../../core/services/storage/local_store.dart';
import '../models/customer.dart';
import 'customer_repository.dart';
import 'mock_customer_repository.dart';

/// Customers in Drift (source of truth), dual-written to [LocalStore] so the
/// rollback to the LocalStore backend loses nothing (DEC-126).
///
/// The controller's in-memory list stays authoritative in the session: this
/// class only persists what it is given. When Drift cannot be used (open,
/// copy or write failure) the session falls back to LocalStore and sets the
/// stale key, so the next start re-copies LocalStore into Drift first.
class DriftCustomerRepository implements CustomerRepository {
  DriftCustomerRepository({
    required DatabaseProvider provider,
    required LocalStore store,
    required StartupDiagnostics diagnostics,
    required UuidGenerator uuid,
    CustomersMigrator? migrator,
    DateTime Function()? now,
  }) : _provider = provider,
       _store = store,
       _diagnostics = diagnostics,
       _uuid = uuid,
       _migrator = migrator ?? CustomersMigrator(uuid: uuid, now: now),
       _now = now ?? DateTime.now,
       _fallback = MockCustomerRepository(store);

  final DatabaseProvider _provider;
  final LocalStore _store;
  final StartupDiagnostics _diagnostics;
  final UuidGenerator _uuid;
  final CustomersMigrator _migrator;
  final DateTime Function() _now;
  final MockCustomerRepository _fallback;

  /// Null until Drift loaded successfully, and again after a failure.
  AxpertDatabase? _db;

  @override
  Future<List<Customer>> load() async {
    try {
      final db = await _provider.open();
      final outcome = await _migrator.ensureCopied(db, _store);
      final report = outcome.report;
      if (report != null && report.hasFindings) {
        _diagnostics.record(
          'customers copy report',
          report.toJson(),
          StackTrace.empty,
        );
      }
      final list = await CustomerRows.readList(db);
      _db = db;
      return list;
    } on Object catch (error, stackTrace) {
      await _degrade('customers load', error, stackTrace);
      return _fallback.load();
    }
  }

  @override
  Future<void> save(List<Customer> customers) async {
    final db = _db;
    if (db == null) {
      await _markStale();
      return _fallback.save(customers);
    }
    final normalized = CustomerRows.normalize(customers).customers;
    try {
      final now = _now().toUtc().toIso8601String();
      await db.durableTransaction(
        () => CustomerRows.apply(db, normalized, now: now, uuid: _uuid),
      );
    } on Object catch (error, stackTrace) {
      await _degrade('customers save', error, stackTrace);
      return _fallback.save(customers);
    }
    try {
      await _store.write(StorageKeys.customers, <Map<String, dynamic>>[
        for (final c in normalized) c.toJson(),
      ]);
    } on Object catch (error, stackTrace) {
      // Drift is already saved; only the rollback copy is behind.
      _diagnostics.record('customers dual-write', error, stackTrace);
    }
  }

  Future<void> _degrade(String stage, Object error, StackTrace stackTrace) {
    _db = null;
    _diagnostics.record(stage, error, stackTrace);
    return _markStale();
  }

  Future<void> _markStale() async {
    try {
      await _store.write(StorageKeys.customersDriftStale, true);
    } on Object catch (error, stackTrace) {
      _diagnostics.record('customers stale marker', error, stackTrace);
    }
  }
}

/// The rollback backend: LocalStore only. Every session marks Drift stale, so
/// switching back to Drift re-copies first (DEC-126).
class LocalStoreCustomerRepository implements CustomerRepository {
  LocalStoreCustomerRepository(this._store)
    : _inner = MockCustomerRepository(_store);

  final LocalStore _store;
  final MockCustomerRepository _inner;

  @override
  Future<List<Customer>> load() async {
    await _store.write(StorageKeys.customersDriftStale, true);
    return _inner.load();
  }

  @override
  Future<void> save(List<Customer> customers) async {
    await _store.write(StorageKeys.customersDriftStale, true);
    return _inner.save(customers);
  }
}
