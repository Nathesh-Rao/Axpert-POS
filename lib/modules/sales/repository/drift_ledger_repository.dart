import '../../../core/bindings/startup_diagnostics.dart';
import '../../../core/bindings/startup_timeline.dart';
import '../../../core/database/axpert_database.dart';
import '../../../core/database/migration/product_rows.dart';
import '../../../core/database/migration/sale_rows.dart';
import '../../../core/database/persist_outcome.dart';
import '../../../core/identifiers/uuid_generator.dart';
import '../../../core/services/inventory/inventory_service.dart';
import '../../../core/utils/serial_queue.dart';
import '../../../features/inventory/data/drift_inventory_repository.dart';
import '../../../features/payment/data/repositories/drift_payment_method_repository.dart';
import '../../../features/products/data/repositories/drift_product_repository.dart';
import '../../../features/products/domain/entities/product.dart';
import '../../customers/models/customer.dart';
import '../../customers/repository/drift_customer_repository.dart';
import '../../pos/repository/checkout_repository.dart';
import '../../returns/repository/return_repository.dart';
import '../../../features/payment/domain/entities/payment_result.dart';
import '../models/sale.dart';
import 'drift_sale_repository.dart';
import '../../../core/utils/epoch_time.dart';

/// The checkout and refund as ONE Drift transaction each (DEC-129).
///
/// A checkout writes the sale, its lines, its payment, the changed stock rows
/// and the customer points together; a refund writes the sale's returned
/// quantities and the restored stock together. The three Drift repositories
/// keep their own snapshots and mirrors; this class borrows their staging
/// methods, runs everything on the shared write queue, adopts the snapshots
/// only after the commit and writes the LocalStore mirrors afterwards.
///
/// When the transaction fails (rolled back, nothing written to Drift) the
/// repositories leave Drift for the session and the lists go to LocalStore
/// (the D1 to D4 fallback); only if that fails too is the outcome `failed`.
class DriftLedgerRepository implements CheckoutRepository, ReturnRepository {
  DriftLedgerRepository({
    required this.sales,
    required this.products,
    required this.customers,
    required SerialQueue queue,
    required UuidGenerator uuid,
    required StartupDiagnostics diagnostics,
    this.inventory,
    DateTime Function()? now,
  }) : _queue = queue,
       _uuid = uuid,
       _diagnostics = diagnostics,
       _now = now ?? DateTime.now;

  final DriftSaleRepository sales;
  final DriftProductRepository products;
  final DriftCustomerRepository customers;

  /// The stock ledger, written inside the same transaction as the sale. Null
  /// (tests, unscoped legacy mode) means no inventory rows are written.
  final DriftInventoryRepository? inventory;
  final SerialQueue _queue;
  final UuidGenerator _uuid;
  final StartupDiagnostics _diagnostics;
  final DateTime Function() _now;

  @override
  Future<PersistOutcome> commit(CheckoutCommit commit) => _queue.run(
    () => _run(
      salesAfter: commit.salesAfter,
      productsAfter: commit.productsAfter,
      customersAfter: commit.customersAfter,
      payment: commit.payment,
      paymentAt: EpochTime.parseOrZero(commit.sale.date),
      stockFor: (ids) => _saleMovements(commit.sale, ids),
      label: 'checkout',
    ),
  );

  @override
  Future<PersistOutcome> applyRefund(RefundCommit commit) => _queue.run(
    () => _run(
      salesAfter: commit.sales,
      productsAfter: commit.products,
      stockFor: (ids) => _refundMovements(commit, ids),
      label: 'refund',
    ),
  );

  Future<PersistOutcome> _run({
    required List<Sale> salesAfter,
    required List<Product> productsAfter,
    List<Customer>? customersAfter,
    PaymentResult? payment,
    int? paymentAt,
    List<StockMovement> Function(Map<int, String> productIds)? stockFor,
    required String label,
  }) async {
    final db = sales.database;
    final sameDb =
        db != null &&
        identical(db, products.database) &&
        (customersAfter == null || identical(db, customers.database));
    if (!sameDb) {
      return _separately(salesAfter, productsAfter, customersAfter);
    }
    try {
      final now = EpochTime.fromDateTime(_now());
      final salePlan = sales.stage(salesAfter, now: now);
      final productPlan = products.stage(productsAfter, now: now);
      final rows = salePlan.rowCount + productPlan.rowCount;
      await StartupTimeline.logged(
        '$label commit ($rows rows)',
        () => db.durableTransaction(() async {
          await SaleRows.write(
            db,
            salePlan,
            now: now,
            uuid: _uuid,
            scope: sales.scope,
          );
          if (payment != null) {
            await SaleRows.insertPayment(
              db,
              payment,
              occurredAt: paymentAt ?? now,
              now: now,
              methodId: sales.scope.storeId == null
                  ? null
                  : await DriftPaymentMethodRepository.idForCode(
                      db,
                      sales.scope.storeId!,
                      payment.method.name,
                    ),
            );
          }
          await ProductRows.write(db, productPlan, now: now);
          if (customersAfter != null) {
            await customers.writeWithin(db, customersAfter, now: now);
          }
          await _writeStock(db, stockFor, now);
        }),
      );
      // Only after the commit: a failed transaction leaves the snapshots.
      sales.adopt(salePlan);
      products.adopt(productPlan);
    } on Object catch (error, stackTrace) {
      if (sales.scope.scoped) {
        // Scoped mode has no LocalStore fallback: the sale is not saved.
        _diagnostics.record('$label commit', error, stackTrace);
        return PersistOutcome.failed;
      }
      return _failover(
        '$label commit',
        error,
        stackTrace,
        salesAfter,
        productsAfter,
        customersAfter,
      );
    }
    await StartupTimeline.logged(
      '$label mirror',
      () => Future.wait(<Future<void>>[
        sales.mirror(salesAfter),
        products.mirror(productsAfter),
        if (customersAfter != null) customers.mirror(customersAfter),
      ]),
    );
    return PersistOutcome.saved;
  }

  /// Product uuids of the current snapshot, by legacy id.
  Map<int, String> get _productUuids => {
    for (final e in products.snapshot.entries) e.key: e.value.uuid,
  };

  List<StockMovement> _saleMovements(Sale sale, Map<int, String> ids) => [
    for (final line in sale.cart.lines)
      if (ids[line.product.id] != null)
        StockMovement(
          productId: ids[line.product.id]!,
          deltaMilli: -line.qty.milli,
          reason: StockReason.sale,
          refType: 'sale',
          refId: sale.saleId ?? sale.number,
        ),
  ];

  List<StockMovement> _refundMovements(
    RefundCommit commit,
    Map<int, String> ids,
  ) {
    final number = commit.request.saleNumber;
    final sale = commit.sales.where((s) => s.number == number).firstOrNull;
    return [
      for (final e in commit.request.entries.entries)
        if (ids[e.key] != null && e.value.milli > 0)
          StockMovement(
            productId: ids[e.key]!,
            deltaMilli: e.value.milli,
            reason: StockReason.returned,
            refType: 'sale',
            refId: sale?.saleId ?? number,
          ),
    ];
  }

  /// Writes the stock movements of this commit inside its transaction. The
  /// cache units are read from the snapshot BEFORE the commit is adopted. A
  /// blocked plan (stock would go below zero in a store that forbids it)
  /// throws so the whole transaction rolls back.
  Future<void> _writeStock(
    AxpertDatabase db,
    List<StockMovement> Function(Map<int, String> productIds)? stockFor,
    int now,
  ) async {
    final repository = inventory;
    final storeId = sales.scope.storeId;
    if (repository == null || storeId == null || stockFor == null) return;
    final ids = _productUuids;
    final movements = stockFor(ids);
    if (movements.isEmpty) return;
    final byUuid = {for (final e in ids.entries) e.value: e.key};
    final plan = await repository.applyWithin(
      db,
      storeId: storeId,
      userId: sales.scope.userId,
      now: now,
      movements: movements,
      stockUnits: {
        for (final m in movements)
          if (products.snapshot[byUuid[m.productId]] != null)
            m.productId: products.snapshot[byUuid[m.productId]]!.product.stock,
      },
    );
    if (plan.isBlocked) throw StockBlockedException(plan.blocked);
  }

  /// At least one store is already on the LocalStore path (an earlier
  /// failure): each repository saves its own list as its normal save does
  /// (Drift for the ones still on it, LocalStore for the others).
  Future<PersistOutcome> _separately(
    List<Sale> salesAfter,
    List<Product> productsAfter,
    List<Customer>? customersAfter,
  ) async {
    try {
      await sales.saveNow(salesAfter);
      await products.saveNow(productsAfter);
      if (customersAfter != null) await customers.saveNow(customersAfter);
    } on Object catch (error, stackTrace) {
      _diagnostics.record('ledger save', error, stackTrace);
      return PersistOutcome.failed;
    }
    final allDrift =
        sales.database != null &&
        products.database != null &&
        (customersAfter == null || customers.database != null);
    return allDrift ? PersistOutcome.saved : PersistOutcome.savedViaFallback;
  }

  Future<PersistOutcome> _failover(
    String stage,
    Object error,
    StackTrace stackTrace,
    List<Sale> salesAfter,
    List<Product> productsAfter,
    List<Customer>? customersAfter,
  ) async {
    await sales.degrade(stage, error, stackTrace);
    await products.degrade(stage, error, stackTrace);
    if (customersAfter != null) {
      await customers.degrade(stage, error, stackTrace);
    }
    final results = await Future.wait(<Future<bool>>[
      _attempt(() => sales.saveFallback(salesAfter)),
      _attempt(() => products.saveFallback(productsAfter)),
      if (customersAfter != null)
        _attempt(() => customers.saveFallback(customersAfter)),
    ]);
    return results.every((ok) => ok)
        ? PersistOutcome.savedViaFallback
        : PersistOutcome.failed;
  }

  Future<bool> _attempt(Future<void> Function() write) async {
    try {
      await write();
      return true;
    } on Object catch (error, stackTrace) {
      _diagnostics.record('ledger fallback', error, stackTrace);
      return false;
    }
  }
}

/// A commit would take stock below zero in a store that forbids it.
class StockBlockedException implements Exception {
  const StockBlockedException(this.shortfalls);

  final List<StockShortfall> shortfalls;

  @override
  String toString() =>
      'StockBlockedException(${shortfalls.map((s) => s.productId).join(', ')})';
}
