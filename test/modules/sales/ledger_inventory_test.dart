// DEC-148: the stock movement is written inside the checkout and refund
// transaction (scoped session), and rolls back with it.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/modules/pos/models/line_key.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/database/persist_outcome.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/features/payment/domain/entities/payment_method.dart';
import 'package:pos_application/features/payment/domain/entities/payment_result.dart';
import 'package:pos_application/features/payment/domain/entities/payment_status.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/session/store_scope.dart';
import 'package:pos_application/core/utils/serial_queue.dart';
import 'package:pos_application/features/inventory/data/drift_inventory_repository.dart';
import 'package:pos_application/features/products/data/repositories/drift_product_repository.dart';
import 'package:pos_application/features/products/domain/entities/product.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/customers/repository/drift_customer_repository.dart';
import 'package:pos_application/modules/pos/repository/checkout_repository.dart';
import 'package:pos_application/modules/returns/models/refund_request.dart';
import 'package:pos_application/modules/returns/repository/return_repository.dart';
import 'package:pos_application/modules/sales/repository/drift_ledger_repository.dart';
import 'package:pos_application/modules/sales/repository/drift_sale_repository.dart';

import '../../support/ledger_fixtures.dart';
import '../../support/product_fixtures.dart';
import '../../support/test_session.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  final AxpertDatabase db;

  @override
  Future<AxpertDatabase> open() async => db;

  @override
  Future<void> close() async {}
}

const String _id1 = '11111111-1111-4111-8111-111111111111';
const String _id2 = '22222222-2222-4222-8222-222222222222';

void main() {
  late AxpertDatabase db;
  late DriftSaleRepository sales;
  late DriftProductRepository products;
  late DriftCustomerRepository customers;
  late DriftLedgerRepository ledger;
  late DriftInventoryRepository inventory;
  late StartupDiagnostics diagnostics;
  late List<Product> prods;
  late List<Customer> custs;

  setUp(() async {
    MockDelay.provider = () => Duration.zero;
    db = AxpertDatabase(NativeDatabase.memory());
    await db.customStatement(
      "INSERT INTO currencies (code, name, symbol, exponent, grouping, "
      "created_at, updated_at) VALUES ('INR', 'Rupee', 'R', 2, 'lakh', 1, 1)",
    );
    await db.customStatement(
      "INSERT INTO stores (id, name, currency_code, created_at, updated_at) "
      "VALUES ('s1', 'Shop', 'INR', 1, 1)",
    );
    await db.customStatement(
      "INSERT INTO users (id, username, display_name, role, salt, "
      "password_hash, hash_algo, created_at, updated_at) "
      "VALUES ('u1', 'u1', 'U', 'cashier', 's', 'h', 'a', 1, 1)",
    );
    final scope = StoreScope()
      ..set(storeId: 's1', userId: 'u1', currency: CurrencyRegistry.inr);
    final store = legacySeededStore();
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
      scope: scope,
    );
    products = DriftProductRepository(
      provider: provider,
      store: store,
      diagnostics: diagnostics,
      uuid: uuid,
      queue: queue,
      scope: scope,
    );
    customers = DriftCustomerRepository(
      provider: provider,
      store: store,
      diagnostics: diagnostics,
      uuid: uuid,
      queue: queue,
    );
    inventory = DriftInventoryRepository(provider: provider, uuid: uuid);
    ledger = DriftLedgerRepository(
      sales: sales,
      products: products,
      customers: customers,
      queue: queue,
      uuid: uuid,
      diagnostics: diagnostics,
      inventory: inventory,
    );
    await sales.load();
    await products.load();
    await products.save([for (var i = 1; i <= 3; i++) prod(i, stock: 10)]);
    prods = await products.load();
    custs = await customers.load();
  });
  tearDown(() => db.close());

  Product sold(Product p, int units) => p.copyWith(stock: p.stock - units);

  CheckoutCommit checkout(String number, String saleId) {
    final sale = ledgerSale(
      number,
      saleId: saleId,
      productIds: [prods[0].id, prods[1].id],
      customerId: custs[1].id,
      customerName: custs[1].name,
    );
    return CheckoutCommit(
      sale: sale,
      payment: null,
      salesAfter: [sale],
      productsAfter: [sold(prods[0], 2), sold(prods[1], 2), prods[2]],
      customersAfter: custs,
    );
  }

  Future<Map<String, int>> balances() => inventory.balances('s1');

  Future<int> txCount() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM inventory_transactions')
              .getSingle())
          .read<int>('n');

  test('a checkout writes the sale movement and lowers the balance', () async {
    final outcome = await ledger.commit(checkout('AX000001', _id1));

    expect(outcome, PersistOutcome.saved);
    final b = await balances();
    final uuids = {
      for (final e in products.snapshot.entries) e.key: e.value.uuid,
    };
    // First sale of a product creates its balance (opening) then sells 2.
    expect(b[uuids[prods[0].id]], 8000);
    expect(b[uuids[prods[1].id]], 8000);
    final rows = await inventory.transactions('s1');
    final saleRows = rows.where((t) => t.reason.code == 'sale').toList();
    expect(saleRows, hasLength(2));
    expect(saleRows.map((t) => t.deltaMilli), everyElement(-2000));
    expect(saleRows.map((t) => t.refId), everyElement(_id1));
    expect(saleRows.map((t) => t.refType), everyElement('sale'));
    expect(saleRows.map((t) => t.userId), everyElement('u1'));
    expect(rows.where((t) => t.reason.code == 'opening'), hasLength(2));
    expect(diagnostics.hasFailures, isFalse);
  });

  test('a failure in the inventory insert rolls the whole sale back', () async {
    await db.customStatement(
      'CREATE TRIGGER fail_inv BEFORE INSERT ON inventory_transactions '
      "BEGIN SELECT RAISE(ABORT, 'injected'); END",
    );

    final outcome = await ledger.commit(checkout('AX000001', _id1));

    expect(outcome, PersistOutcome.failed); // scoped: no LocalStore fallback
    expect(
      (await db.customSelect('SELECT COUNT(*) AS n FROM sales').getSingle())
          .read<int>('n'),
      0,
    );
    expect(await txCount(), 0);
    expect(await balances(), isEmpty);
    final stock = await db
        .customSelect('SELECT stock FROM products ORDER BY position')
        .get();
    expect(stock.map((r) => r.read<int>('stock')), [10, 10, 10]);
    expect(
      diagnostics.failures.map((f) => f.stage),
      contains('checkout commit'),
    );
  });

  test(
    'a sale past the balance is refused when the store forbids it',
    () async {
      final over = ledgerSale(
        'AX000001',
        saleId: _id1,
        productIds: [prods[0].id],
        customerId: custs[1].id,
        customerName: custs[1].name,
      ); // quantity 2
      final c = CheckoutCommit(
        sale: over,
        payment: null,
        salesAfter: [over],
        productsAfter: [sold(prods[0], 2), prods[1], prods[2]],
        customersAfter: custs,
      );
      // The cache says 1 unit, so the balance is created with 1 and the sale of
      // 2 would go below zero.
      await db.customStatement(
        'UPDATE products SET stock = 1 WHERE legacy_id = ?',
        [prods[0].id],
      );
      await products.load();

      final outcome = await ledger.commit(c);

      expect(outcome, PersistOutcome.failed);
      expect(await txCount(), 0);
      expect(
        (await db.customSelect('SELECT COUNT(*) AS n FROM sales').getSingle())
            .read<int>('n'),
        0,
      );
      expect(
        diagnostics.failures.map((f) => f.error.toString()).join(),
        contains('StockBlockedException'),
      );
    },
  );

  test('a store that allows negative stock sells past zero', () async {
    await db.customStatement('UPDATE stores SET allow_negative_stock = 1');
    final over = ledgerSale(
      'AX000001',
      saleId: _id1,
      productIds: [prods[0].id],
      customerId: custs[1].id,
      customerName: custs[1].name,
    );
    await db.customStatement(
      'UPDATE products SET stock = 1 WHERE legacy_id = ?',
      [prods[0].id],
    );
    await products.load();
    final c = CheckoutCommit(
      sale: over,
      payment: null,
      salesAfter: [over],
      productsAfter: [prods[0].copyWith(stock: -1), prods[1], prods[2]],
      customersAfter: custs,
    );

    final outcome = await ledger.commit(c);

    expect(outcome, PersistOutcome.saved);
    final b = await balances();
    expect(b.values, contains(-1000));
    final t = (await inventory.transactions(
      's1',
    )).firstWhere((t) => t.reason.code == 'sale');
    expect(t.note, contains('negative stock'));
  });

  test('a refund writes a return movement and restores the balance', () async {
    final c = checkout('AX000001', _id1);
    await ledger.commit(c);
    final sale = c.sale;
    final after = [
      sale.copyWith(returned: {LineKey(prods[0].id): const Qty(1000)}),
    ];

    final outcome = await ledger.applyRefund(
      RefundCommit(
        request: RefundRequest(
          saleNumber: sale.number,
          entries: {LineKey(prods[0].id): const Qty(1000)},
        ),
        sales: after,
        products: [prods[0].copyWith(stock: 9), sold(prods[1], 2), prods[2]],
      ),
    );

    expect(outcome, PersistOutcome.saved);
    final uuid = products.snapshot[prods[0].id]!.uuid;
    expect((await balances())[uuid], 9000);
    final ret = (await inventory.transactions(
      's1',
    )).where((t) => t.reason.code == 'return').single;
    expect((ret.deltaMilli, ret.refId, ret.productId), (1000, _id1, uuid));
  });

  test('two sales of the same product keep an exact running balance', () async {
    await ledger.commit(checkout('AX000001', _id1));
    final sale2 = ledgerSale(
      'AX000002',
      saleId: _id2,
      productIds: [prods[0].id],
      customerId: custs[1].id,
      customerName: custs[1].name,
    );
    await ledger.commit(
      CheckoutCommit(
        sale: sale2,
        payment: null,
        salesAfter: [checkout('AX000001', _id1).sale, sale2],
        productsAfter: [
          prods[0].copyWith(stock: 6),
          sold(prods[1], 2),
          prods[2],
        ],
        customersAfter: custs,
      ),
    );

    final uuid = products.snapshot[prods[0].id]!.uuid;
    expect((await balances())[uuid], 6000);
  });

  test(
    'the payment row points at the store payment method (DEC-149)',
    () async {
      await db.customStatement(
        'INSERT INTO payment_methods (id, store_id, code, name, type, '
        "created_at, updated_at) VALUES ('pm-cash', 's1', 'cash', 'Cash', "
        "'cash', 1, 1)",
      );
      final c = checkout('AX000001', _id1);

      final outcome = await ledger.commit(
        CheckoutCommit(
          sale: c.sale,
          payment: const PaymentResult(
            paymentId: 'pay-1',
            saleId: _id1,
            amount: Money(21420, CurrencyRegistry.inr),
            method: PaymentMethod.cash,
            status: PaymentStatus.succeeded,
          ),
          salesAfter: c.salesAfter,
          productsAfter: c.productsAfter,
          customersAfter: c.customersAfter,
        ),
      );

      expect(outcome, PersistOutcome.saved);
      final pay = await db.select(db.paymentEntries).getSingle();
      expect((pay.method, pay.methodId), ('cash', 'pm-cash'));
    },
  );

  test('without a method row the payment keeps a null method_id', () async {
    final c = checkout('AX000001', _id1);

    await ledger.commit(
      CheckoutCommit(
        sale: c.sale,
        payment: const PaymentResult(
          paymentId: 'pay-1',
          saleId: _id1,
          amount: Money(21420, CurrencyRegistry.inr),
          method: PaymentMethod.card,
          status: PaymentStatus.succeeded,
        ),
        salesAfter: c.salesAfter,
        productsAfter: c.productsAfter,
        customersAfter: c.customersAfter,
      ),
    );

    final pay = await db.select(db.paymentEntries).getSingle();
    expect(pay.method, 'card');
    expect(pay.methodId, isNull);
  });
}
