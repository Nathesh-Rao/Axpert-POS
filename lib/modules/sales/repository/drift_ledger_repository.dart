import '../../../core/bindings/startup_diagnostics.dart';
import '../../../core/bindings/startup_timeline.dart';
import '../../../core/database/migration/product_rows.dart';
import '../../../core/database/migration/sale_rows.dart';
import '../../../core/database/persist_outcome.dart';
import '../../../core/identifiers/uuid_generator.dart';
import '../../../core/utils/serial_queue.dart';
import '../../../features/products/data/repositories/drift_product_repository.dart';
import '../../../features/products/domain/entities/product.dart';
import '../../customers/models/customer.dart';
import '../../customers/repository/drift_customer_repository.dart';
import '../../pos/repository/checkout_repository.dart';
import '../../returns/repository/return_repository.dart';
import '../../../features/payment/domain/entities/payment_result.dart';
import '../models/sale.dart';
import 'drift_sale_repository.dart';

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
    DateTime Function()? now,
  }) : _queue = queue,
       _uuid = uuid,
       _diagnostics = diagnostics,
       _now = now ?? DateTime.now;

  final DriftSaleRepository sales;
  final DriftProductRepository products;
  final DriftCustomerRepository customers;
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
      paymentAt: commit.sale.date,
      label: 'checkout',
    ),
  );

  @override
  Future<PersistOutcome> applyRefund(RefundCommit commit) => _queue.run(
    () => _run(
      salesAfter: commit.sales,
      productsAfter: commit.products,
      label: 'refund',
    ),
  );

  Future<PersistOutcome> _run({
    required List<Sale> salesAfter,
    required List<Product> productsAfter,
    List<Customer>? customersAfter,
    PaymentResult? payment,
    String? paymentAt,
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
      final now = _now().toUtc().toIso8601String();
      final salePlan = sales.stage(salesAfter, now: now);
      final productPlan = products.stage(productsAfter, now: now);
      final rows = salePlan.rowCount + productPlan.rowCount;
      await StartupTimeline.logged(
        '$label commit ($rows rows)',
        () => db.durableTransaction(() async {
          await SaleRows.write(db, salePlan, now: now, uuid: _uuid);
          if (payment != null) {
            await SaleRows.insertPayment(
              db,
              payment,
              occurredAt: paymentAt ?? now,
              now: now,
            );
          }
          await ProductRows.write(db, productPlan, now: now);
          if (customersAfter != null) {
            await customers.writeWithin(db, customersAfter, now: now);
          }
        }),
      );
      // Only after the commit: a failed transaction leaves the snapshots.
      sales.adopt(salePlan);
      products.adopt(productPlan);
    } on Object catch (error, stackTrace) {
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
