// DEC-129: the checkout and the refund as ONE Drift transaction. Fault
// injection by SQLite triggers (RAISE(ABORT)) at every table the transaction
// touches: after a failure NOTHING of the unit is in Drift.
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/modules/pos/models/line_key.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/database/persist_outcome.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/core/utils/serial_queue.dart';
import 'package:pos_application/features/payment/domain/entities/payment_method.dart';
import 'package:pos_application/features/payment/domain/entities/payment_result.dart';
import 'package:pos_application/features/payment/domain/entities/payment_status.dart';
import 'package:pos_application/features/products/data/repositories/drift_product_repository.dart';
import 'package:pos_application/features/products/domain/entities/product.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/customers/repository/drift_customer_repository.dart';
import 'package:pos_application/modules/pos/repository/checkout_repository.dart';
import 'package:pos_application/modules/returns/models/refund_request.dart';
import 'package:pos_application/modules/returns/repository/return_repository.dart';
import 'package:pos_application/modules/sales/models/sale.dart';
import 'package:pos_application/modules/sales/repository/drift_ledger_repository.dart';
import 'package:pos_application/modules/sales/repository/drift_sale_repository.dart';

import '../../support/ledger_fixtures.dart';
import '../../support/test_session.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  final AxpertDatabase db;

  @override
  Future<AxpertDatabase> open() async => db;

  @override
  Future<void> close() async {}
}

/// A store whose writes can be made to fail.
class _FlakyStore extends InMemoryLocalStore {
  _FlakyStore() : super(legacySeededStore().snapshot());

  bool failWrites = false;

  @override
  Future<void> write(String key, Object? json) async {
    if (failWrites) throw StateError('store unavailable');
    return super.write(key, json);
  }
}

const String _id1 = '11111111-1111-4111-8111-111111111111';
const String _id2 = '22222222-2222-4222-8222-222222222222';

void main() {
  late AxpertDatabase db;
  late _FlakyStore store;
  late StartupDiagnostics diagnostics;
  late DriftSaleRepository sales;
  late DriftProductRepository products;
  late DriftCustomerRepository customers;
  late DriftLedgerRepository ledger;
  late List<Product> prods;
  late List<Customer> custs;

  setUp(() async {
    MockDelay.provider = () => Duration.zero;
    db = AxpertDatabase(NativeDatabase.memory());
    store = _FlakyStore();
    diagnostics = StartupDiagnostics();
    final queue = SerialQueue();
    final uuid = UuidV4Generator();
    final provider = _Provider(db);
    sales = DriftSaleRepository(
      provider: provider,
      store: store,
      diagnostics: diagnostics,
      uuid: uuid,
      queue: queue,
    );
    products = DriftProductRepository(
      provider: provider,
      store: store,
      diagnostics: diagnostics,
      uuid: uuid,
      queue: queue,
    );
    customers = DriftCustomerRepository(
      provider: provider,
      store: store,
      diagnostics: diagnostics,
      uuid: uuid,
      queue: queue,
    );
    ledger = DriftLedgerRepository(
      sales: sales,
      products: products,
      customers: customers,
      queue: queue,
      uuid: uuid,
      diagnostics: diagnostics,
    );
    await sales.load();
    prods = await products.load();
    custs = await customers.load();
  });
  tearDown(() => db.close());

  Product sold(Product p, int units) => p.copyWith(stock: p.stock - units);

  CheckoutCommit checkout({
    required String number,
    required String saleId,
    List<Sale> before = const <Sale>[],
    List<Product>? productsBefore,
    List<Customer>? customersBefore,
    bool withPayment = true,
  }) {
    final p0 = (productsBefore ?? prods);
    final sale = ledgerSale(
      number,
      saleId: saleId,
      productIds: [p0[0].id, p0[1].id],
      customerId: custs[1].id,
      customerName: custs[1].name,
    );
    final c0 = customersBefore ?? custs;
    return CheckoutCommit(
      sale: sale,
      payment: withPayment
          ? PaymentResult(
              paymentId: 'pay-$number',
              saleId: saleId,
              amount: const Money(21420, CurrencyRegistry.inr),
              method: PaymentMethod.cash,
              status: PaymentStatus.succeeded,
            )
          : null,
      salesAfter: [...before, sale],
      productsAfter: [sold(p0[0], 2), sold(p0[1], 2), ...p0.skip(2)],
      customersAfter: [
        for (final c in c0)
          c.id == custs[1].id
              ? Customer(
                  id: c.id,
                  name: c.name,
                  phone: c.phone,
                  email: c.email,
                  member: c.member,
                  points: c.points - 10,
                )
              : c,
      ],
    );
  }

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
          .read<int>('n');

  Future<List<int>> stocks() async => [
    for (final r
        in await db
            .customSelect('SELECT stock FROM products ORDER BY position')
            .get())
      r.read<int>('stock'),
  ];

  Future<List<int>> points() async => [
    for (final r
        in await db
            .customSelect('SELECT points FROM customers ORDER BY position')
            .get())
      r.read<int>('points'),
  ];

  Future<void> trigger(String when, String table) => db.customStatement(
    'CREATE TRIGGER fail_${when}_$table BEFORE $when ON $table '
    "BEGIN SELECT RAISE(ABORT, 'injected'); END",
  );

  test('a checkout writes sale, lines, payment, stock and points', () async {
    final stockBefore = await stocks();
    final pointsBefore = await points();

    final outcome = await ledger.commit(
      checkout(number: 'AX000001', saleId: _id1),
    );

    expect(outcome, PersistOutcome.saved);
    expect(await count('sales'), 1);
    expect(await count('sale_lines'), 2);
    final pay = await db.select(db.paymentEntries).getSingle();
    expect(
      (pay.id, pay.saleId, pay.method, pay.amountMinor),
      ('pay-AX000001', _id1, 'cash', 21420),
    );
    final stockAfter = await stocks();
    expect(stockAfter[0], stockBefore[0] - 2);
    expect(stockAfter[1], stockBefore[1] - 2);
    expect(stockAfter.skip(2), stockBefore.skip(2));
    final pointsAfter = await points();
    expect(pointsAfter[1], pointsBefore[1] - 10);
    expect(pointsAfter[0], pointsBefore[0]);
    expect(diagnostics.hasFailures, isFalse);
  });

  test('only the changed product rows are written', () async {
    await ledger.commit(checkout(number: 'AX000001', saleId: _id1));

    final changed = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM products WHERE updated_at <> created_at',
        )
        .getSingle();
    expect(changed.read<int>('n'), 2);
    final custChanged = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM customers WHERE updated_at <> created_at',
        )
        .getSingle();
    expect(custChanged.read<int>('n'), 1);
  });

  test(
    'the mirrors hold the same JSON as before, saleId on new sales',
    () async {
      final c = checkout(number: 'AX000001', saleId: _id1);

      await ledger.commit(c);

      expect(await store.read(StorageKeys.sales), [
        for (final s in c.salesAfter) s.toJson(),
      ]);
      expect(await store.read(StorageKeys.products), [
        for (final p in c.productsAfter) p.toJson(),
      ]);
      expect(await store.read(StorageKeys.customers), [
        for (final x in c.customersAfter) x.toJson(),
      ]);
      expect(await store.has(StorageKeys.salesDriftStale), isFalse);
    },
  );

  test('a credit sale writes no payment row', () async {
    await ledger.commit(
      checkout(number: 'AX000001', saleId: _id1, withPayment: false),
    );

    expect(await count('sales'), 1);
    expect(await count('payments'), 0);
  });

  test('the sale resolves its customer and product links', () async {
    await ledger.commit(checkout(number: 'AX000001', saleId: _id1));

    final row = await db.select(db.saleEntries).getSingle();
    expect(row.customerId, isNotNull);
    final lines = await db.select(db.saleLineEntries).get();
    expect(lines.map((l) => l.productId), everyElement(isNotNull));
  });

  // Fault injection: nothing of the unit is in Drift after a failure.
  final failPoints = <String, (String when, String table)>{
    'sale': ('INSERT', 'sales'),
    'lines': ('INSERT', 'sale_lines'),
    'payment': ('INSERT', 'payments'),
    'stock': ('UPDATE', 'products'),
    'points': ('UPDATE', 'customers'),
  };
  for (final entry in failPoints.entries) {
    test('failure at ${entry.key}: nothing persisted in Drift, fallback '
        'saves the lists', () async {
      final stockBefore = await stocks();
      final pointsBefore = await points();
      await trigger(entry.value.$1, entry.value.$2);
      final c = checkout(number: 'AX000001', saleId: _id1);

      final outcome = await ledger.commit(c);

      expect(outcome, PersistOutcome.savedViaFallback);
      expect(await count('sales'), 0);
      expect(await count('sale_lines'), 0);
      expect(await count('payments'), 0);
      expect(await stocks(), stockBefore);
      expect(await points(), pointsBefore);
      // The fallback wrote all three lists to LocalStore, stale keys are set.
      expect(await store.read(StorageKeys.sales), [
        for (final s in c.salesAfter) s.toJson(),
      ]);
      expect(await store.read(StorageKeys.products), [
        for (final p in c.productsAfter) p.toJson(),
      ]);
      expect(await store.read(StorageKeys.customers), [
        for (final x in c.customersAfter) x.toJson(),
      ]);
      expect(await store.read(StorageKeys.salesDriftStale), true);
      expect(await store.read(StorageKeys.productsDriftStale), true);
      expect(await store.read(StorageKeys.customersDriftStale), true);
      expect(
        diagnostics.failures.map((f) => f.stage),
        contains('checkout commit'),
      );
    });
  }

  test(
    'Drift and LocalStore both fail: outcome failed, Drift unchanged',
    () async {
      final stockBefore = await stocks();
      await trigger('INSERT', 'sales');
      store.failWrites = true;

      final outcome = await ledger.commit(
        checkout(number: 'AX000001', saleId: _id1),
      );

      expect(outcome, PersistOutcome.failed);
      expect(await count('sales'), 0);
      expect(await stocks(), stockBefore);
    },
  );

  test('after a failover later commits write the full lists again', () async {
    await trigger('INSERT', 'sales');
    final first = checkout(number: 'AX000001', saleId: _id1);
    expect(await ledger.commit(first), PersistOutcome.savedViaFallback);

    final second = checkout(
      number: 'AX000002',
      saleId: _id2,
      before: first.salesAfter,
      productsBefore: first.productsAfter,
      customersBefore: first.customersAfter,
    );
    final outcome = await ledger.commit(second);

    expect(outcome, PersistOutcome.savedViaFallback);
    final stored = await store.read(StorageKeys.sales) as List<dynamic>;
    expect(stored.map((e) => (e as Map)['number']), ['AX000001', 'AX000002']);
    expect(await count('sales'), 0, reason: 'the session left Drift');
  });

  test('overlapping checkouts run in call order and both persist', () async {
    final first = checkout(number: 'AX000001', saleId: _id1);
    final second = checkout(
      number: 'AX000002',
      saleId: _id2,
      before: first.salesAfter,
      productsBefore: first.productsAfter,
      customersBefore: first.customersAfter,
    );

    final a = ledger.commit(first);
    final b = ledger.commit(second);
    expect(await Future.wait([a, b]), [
      PersistOutcome.saved,
      PersistOutcome.saved,
    ]);

    final rows = await (db.select(
      db.saleEntries,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    expect(rows.map((r) => r.number), ['AX000001', 'AX000002']);
    expect((await stocks())[0], prods[0].stock - 4);
    final stored = await store.read(StorageKeys.sales) as List<dynamic>;
    expect(stored, hasLength(2));
  });

  test(
    'a favourite toggle queued between two checkouts keeps the order',
    () async {
      final first = checkout(number: 'AX000001', saleId: _id1);
      final a = ledger.commit(first);
      final toggled = [
        for (final p in first.productsAfter)
          p.id == prods[6].id ? p.copyWith(favourite: !p.favourite) : p,
      ];
      final b = products.save(toggled);
      await Future.wait([a, b]);

      final stored = await store.read(StorageKeys.products) as List<dynamic>;
      expect(
        stored.where((e) => (e as Map)['favourite'] == true),
        hasLength(toggled.where((p) => p.favourite).length),
      );
      expect((await stocks())[0], prods[0].stock - 2);
    },
  );

  group('refund', () {
    late CheckoutCommit done;

    setUp(() async {
      done = checkout(number: 'AX000001', saleId: _id1);
      await ledger.commit(done);
    });

    RefundCommit refund() {
      final sale = done.salesAfter.single;
      final id0 = sale.cart.lines.first.product.id;
      return RefundCommit(
        request: RefundRequest(
          saleNumber: sale.number,
          entries: {LineKey(id0): const Qty(1000)},
        ),
        sales: [
          sale.copyWith(returned: {LineKey(id0): const Qty(1000)}),
        ],
        products: [
          for (final p in done.productsAfter)
            p.id == id0 ? p.copyWith(stock: p.stock + 1) : p,
        ],
      );
    }

    test('updates returned and stock in one transaction', () async {
      final stockBefore = await stocks();

      final outcome = await ledger.applyRefund(refund());

      expect(outcome, PersistOutcome.saved);
      final lines = await (db.select(
        db.saleLineEntries,
      )..orderBy([(t) => OrderingTerm.asc(t.lineNo)])).get();
      expect(lines.map((l) => l.returnedQtyMilli), [1000, 0]);
      expect((await stocks())[0], stockBefore[0] + 1);
      final saleRow = await db.select(db.saleEntries).getSingle();
      final productRow = await (db.select(
        db.productEntries,
      )..where((t) => t.legacyId.equals(done.productsAfter[0].id))).getSingle();
      expect(saleRow.updatedAt, productRow.updatedAt, reason: 'one unit');
      final stored = await store.read(StorageKeys.sales) as List<dynamic>;
      expect((stored.single as Map)['returned'], {
        '${done.productsAfter[0].id}': 1000,
      });
    });

    test('a failure at stock rolls the returned quantity back too', () async {
      final stockBefore = await stocks();
      await trigger('UPDATE', 'products');

      final outcome = await ledger.applyRefund(refund());

      expect(outcome, PersistOutcome.savedViaFallback);
      final lines = await db.select(db.saleLineEntries).get();
      expect(lines.map((l) => l.returnedQtyMilli), everyElement(0));
      expect(await stocks(), stockBefore);
      expect((await db.select(db.saleEntries).getSingle()).returnedOrder, '[]');
      expect(await store.read(StorageKeys.salesDriftStale), true);
    });

    test('a failure at the sale rows rolls the stock back too', () async {
      final stockBefore = await stocks();
      await db.customStatement(
        'CREATE TRIGGER fail_sale_update BEFORE UPDATE ON sales '
        "BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );

      final outcome = await ledger.applyRefund(refund());

      expect(outcome, PersistOutcome.savedViaFallback);
      expect(await stocks(), stockBefore);
    });

    test('both stores failing reports failed', () async {
      await trigger('UPDATE', 'products');
      store.failWrites = true;

      expect(await ledger.applyRefund(refund()), PersistOutcome.failed);
    });
  });
}
