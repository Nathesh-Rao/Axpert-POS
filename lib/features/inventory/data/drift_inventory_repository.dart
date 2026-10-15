import 'package:drift/drift.dart';

import '../../../core/database/axpert_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/identifiers/uuid_generator.dart';
import '../../../core/services/inventory/inventory_service.dart';
import '../domain/repositories/inventory_repository.dart';

/// The stock ledger in Drift. Reads open the shared database; [applyWithin]
/// is called by the ledger repository inside its own transaction, so a sale,
/// its payment and its stock movement commit or roll back together.
class DriftInventoryRepository implements InventoryRepository {
  DriftInventoryRepository({
    required DatabaseProvider provider,
    required UuidGenerator uuid,
    InventoryService service = const InventoryService(),
  }) : _provider = provider,
       _uuid = uuid,
       _service = service;

  final DatabaseProvider _provider;
  final UuidGenerator _uuid;
  final InventoryService _service;

  @override
  Future<Map<String, int>> balances(String storeId) async {
    final db = await _provider.open();
    return _balances(db, storeId);
  }

  @override
  Future<List<StockTransaction>> transactions(
    String storeId, {
    String? productId,
    int? limit,
  }) async {
    final db = await _provider.open();
    final query = db.select(db.inventoryTransactionEntries)
      ..where(
        (t) =>
            t.storeId.equals(storeId) &
            t.deletedAt.isNull() &
            (productId == null
                ? const Constant(true)
                : t.productId.equals(productId)),
      )
      ..orderBy([
        (t) => OrderingTerm.desc(t.createdAt),
        (t) => OrderingTerm.desc(t.id),
      ]);
    if (limit != null) query.limit(limit);
    return [
      for (final r in await query.get())
        StockTransaction(
          id: r.id,
          storeId: r.storeId,
          productId: r.productId,
          deltaMilli: r.quantityDeltaMilli,
          reason: StockReason.fromCode(r.reason),
          createdAt: r.createdAt,
          refType: r.refType,
          refId: r.refId,
          userId: r.userId,
          note: r.note,
        ),
    ];
  }

  @override
  Future<bool> allowsNegativeStock(String storeId) async {
    final db = await _provider.open();
    return _allows(db, storeId);
  }

  /// Plans and writes [movements] on [db]; call it inside a transaction.
  /// Returns the plan; a blocked plan is returned unwritten and the caller
  /// must roll its transaction back.
  Future<StockPlan> applyWithin(
    AxpertDatabase db, {
    required String storeId,
    String? userId,
    required int now,
    required List<StockMovement> movements,
    required Map<String, int> stockUnits,
  }) async {
    final ids = {for (final m in movements) m.productId};
    final plan = _service.plan(
      storeId: storeId,
      userId: userId,
      now: now,
      movements: movements,
      balances: await _balances(db, storeId, ids),
      stockUnits: stockUnits,
      allowNegative: await _allows(db, storeId),
      newId: _uuid.generate,
    );
    if (plan.isBlocked) return plan;
    for (final t in plan.transactions) {
      await db
          .into(db.inventoryTransactionEntries)
          .insert(
            InventoryTransactionEntriesCompanion.insert(
              id: t.id,
              storeId: t.storeId,
              productId: t.productId,
              quantityDeltaMilli: t.deltaMilli,
              reason: t.reason.code,
              refType: Value(t.refType),
              refId: Value(t.refId),
              userId: Value(t.userId),
              createdAt: t.createdAt,
              note: Value(t.note),
            ),
          );
    }
    for (final e in plan.balances.entries) {
      await db
          .into(db.inventoryBalanceEntries)
          .insertOnConflictUpdate(
            InventoryBalanceEntriesCompanion.insert(
              storeId: storeId,
              productId: e.key,
              quantityMilli: e.value,
              updatedAt: now,
            ),
          );
    }
    return plan;
  }

  Future<Map<String, int>> _balances(
    AxpertDatabase db,
    String storeId, [
    Iterable<String>? productIds,
  ]) async {
    final query = db.select(db.inventoryBalanceEntries)
      ..where(
        (t) =>
            t.storeId.equals(storeId) &
            (productIds == null
                ? const Constant(true)
                : t.productId.isIn(productIds)),
      );
    return {for (final r in await query.get()) r.productId: r.quantityMilli};
  }

  Future<bool> _allows(AxpertDatabase db, String storeId) async {
    final row = await (db.select(
      db.storeEntries,
    )..where((t) => t.id.equals(storeId))).getSingleOrNull();
    return row?.allowNegativeStock ?? false;
  }
}

/// In-memory stock for tests and the LocalStore path (no Drift): nothing is
/// persisted, balances are empty until a test fills them.
class MockInventoryRepository implements InventoryRepository {
  MockInventoryRepository({
    Map<String, int>? balances,
    this.allowNegative = false,
  }) : _balances = balances ?? <String, int>{};

  final Map<String, int> _balances;
  final bool allowNegative;

  @override
  Future<Map<String, int>> balances(String storeId) async =>
      Map<String, int>.of(_balances);

  @override
  Future<List<StockTransaction>> transactions(
    String storeId, {
    String? productId,
    int? limit,
  }) async => const <StockTransaction>[];

  @override
  Future<bool> allowsNegativeStock(String storeId) async => allowNegative;
}
