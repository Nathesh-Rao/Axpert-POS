import '../../../core/bindings/startup_diagnostics.dart';
import '../../../core/bindings/startup_timeline.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/database/axpert_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/migration/cart_migrator.dart';
import '../../../core/database/migration/cart_rows.dart';
import '../../../core/services/storage/local_store.dart';
import '../../../core/utils/serial_queue.dart';
import '../models/cart.dart';
import 'cart_repository.dart';
import 'mock_cart_repository.dart';

/// The cart draft in Drift (source of truth), dual-written to [LocalStore]
/// so the rollback to the LocalStore backend loses nothing (DEC-130).
///
/// `CartController` keeps the coalescing write-behind (one save in flight,
/// one trailing save with the latest state); this class persists what it is
/// given: one single-row upsert per save plus the old `axpert-cart` mirror.
/// A save whose JSON equals the last one written is skipped. Any read problem
/// resets silently to the empty cart, as before (only a diagnostics record).
/// When Drift cannot be used (open, copy or write failure) the session falls
/// back to LocalStore and sets the stale key, so the next start re-copies
/// LocalStore into Drift first.
class DriftCartRepository implements CartRepository {
  DriftCartRepository({
    required DatabaseProvider provider,
    required LocalStore store,
    required StartupDiagnostics diagnostics,
    SerialQueue? queue,
    CartMigrator? migrator,
    DateTime Function()? now,
  }) : _provider = provider,
       _store = store,
       _diagnostics = diagnostics,
       _saves = queue ?? SerialQueue(),
       _migrator = migrator ?? CartMigrator(now: now),
       _now = now ?? DateTime.now,
       _fallback = MockCartRepository(store);

  final DatabaseProvider _provider;
  final LocalStore _store;
  final StartupDiagnostics _diagnostics;
  final SerialQueue _saves;
  final CartMigrator _migrator;
  final DateTime Function() _now;
  final MockCartRepository _fallback;

  /// Null until Drift loaded successfully, and again after a failure.
  AxpertDatabase? _db;

  /// Canonical JSON of the cart that Drift and the mirror both hold; null
  /// when unknown (nothing loaded yet, unreadable row, a half-failed save).
  String? _lastJson;

  /// For tests.
  String? get lastJson => _lastJson;

  @override
  Future<Cart> load() async {
    try {
      final db = await _provider.open();
      final outcome = await _migrator.ensureCopied(db, _store);
      final report = outcome.report;
      if (report != null && report.hasFindings) {
        _diagnostics.record(
          'cart copy report',
          report.toJson(),
          StackTrace.empty,
        );
      }
      final read = await CartRows.read(db);
      if (read.unreadable) {
        _diagnostics.record(
          'cart unreadable',
          'current_cart row could not be read; reset to the empty cart',
          StackTrace.empty,
        );
      }
      _lastJson = read.json;
      _db = db;
      return read.cart;
    } on Object catch (error, stackTrace) {
      await _degrade('cart load', error, stackTrace);
      return _fallback.load();
    }
  }

  @override
  Future<void> save(Cart cart) => _saves.run(() => _save(cart));

  Future<void> _save(Cart cart) async {
    final db = _db;
    if (db == null) {
      _lastJson = null;
      await _markStale();
      return _fallback.save(cart);
    }
    final json = CartRows.encode(cart);
    if (json == _lastJson) return;
    try {
      final now = _now().toUtc().toIso8601String();
      await StartupTimeline.logged(
        'cart save drift',
        () => CartRows.write(db, json, now: now),
      );
    } on Object catch (error, stackTrace) {
      await _degrade('cart save', error, stackTrace);
      return _fallback.save(cart);
    }
    try {
      await _store.write(StorageKeys.cart, cart.toJson());
      _lastJson = json;
    } on Object catch (error, stackTrace) {
      // Drift is already saved; only the rollback copy is behind.
      _lastJson = null;
      _diagnostics.record('cart dual-write', error, stackTrace);
    }
  }

  Future<void> _degrade(String stage, Object error, StackTrace stackTrace) {
    _db = null;
    _lastJson = null;
    _diagnostics.record(stage, error, stackTrace);
    return _markStale();
  }

  Future<void> _markStale() async {
    try {
      await _store.write(StorageKeys.cartDriftStale, true);
    } on Object catch (error, stackTrace) {
      _diagnostics.record('cart stale marker', error, stackTrace);
    }
  }
}

/// The rollback backend: LocalStore only. Every session marks Drift stale, so
/// switching back to Drift re-copies first (DEC-130).
class LocalStoreCartRepository implements CartRepository {
  LocalStoreCartRepository(this._store) : _inner = MockCartRepository(_store);

  final LocalStore _store;
  final MockCartRepository _inner;

  @override
  Future<Cart> load() async {
    await _store.write(StorageKeys.cartDriftStale, true);
    return _inner.load();
  }

  @override
  Future<void> save(Cart cart) async {
    await _store.write(StorageKeys.cartDriftStale, true);
    return _inner.save(cart);
  }
}
