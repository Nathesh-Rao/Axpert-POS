// DEC-151: a sale line in a packaging deducts BASE units, atomically, and
// keeps its packaging snapshot.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/database/persist_outcome.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/packaging/packaging_ref.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/database/tables/unit_entries.dart';
import 'package:pos_application/features/products/data/repositories/drift_packaging_repositories.dart';
import 'package:pos_application/features/products/domain/entities/packaging_entities.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/sales/models/sale.dart';
import 'package:pos_application/core/services/pricing/money.dart';
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
    await products.save([for (var i = 1; i <= 3; i++) prod(i, stock: 100)]);
    prods = await products.load();
    custs = await customers.load();
  });
  tearDown(() => db.close());

  const carton = PackagingRef(
    id: 'pk1',
    unitName: 'Carton',
    quantityBaseMilli: 24000,
  );

  Future<void> addCartonRow() async {
    final productUuid = products.snapshot[prods[0].id]!.uuid;
    await DriftPackagingRepository(_Provider(db)).save(
      ProductPackaging(
        id: 'pk1',
        productId: productUuid,
        unitId: SeedUnits.carton.id,
        name: 'Carton',
        quantityBaseMilli: 24000,
      ),
    );
  }

  /// A sale of [qty] cartons of product 1 (a carton is 24 pieces at 24 x
  /// the piece price).
  Sale cartonSale(String number, String saleId, Qty qty) {
    final base = ledgerSale(
      number,
      saleId: saleId,
      productIds: [prods[0].id],
      customerId: custs[1].id,
      customerName: custs[1].name,
    );
    final line = CartLine(
      product: prods[0],
      qty: qty,
      price: Money(prods[0].price.minor * 24, CurrencyRegistry.inr),
      discount: Bp.zero,
      packaging: carton,
    );
    return Sale(
      number: base.number,
      saleId: base.saleId,
      date: base.date,
      store: base.store,
      customer: base.customer,
      cart: base.cart.copyWith(lines: [line]),
      totals: base.totals,
      mode: base.mode,
      tendered: base.tendered,
      change: base.change,
      returned: base.returned,
    );
  }

  CheckoutCommit checkoutOf(Sale sale, int stockAfter) => CheckoutCommit(
    sale: sale,
    payment: null,
    salesAfter: [sale],
    productsAfter: [
      prods[0].copyWith(stock: stockAfter),
      prods[1],
      prods[2],
    ],
    customersAfter: custs,
  );

  test('2 cartons deduct 48 pieces and keep the packaging snapshot', () async {
    await addCartonRow();
    final sale = cartonSale('AX000001', _id1, const Qty(2000));

    final outcome = await ledger.commit(checkoutOf(sale, 52));

    expect(outcome, PersistOutcome.saved);
    final uuid = products.snapshot[prods[0].id]!.uuid;
    expect((await inventory.balances('s1'))[uuid], 52000);
    final tx = (await inventory.transactions(
      's1',
    )).where((t) => t.reason.code == 'sale').single;
    expect((tx.deltaMilli, tx.refId), (-48000, _id1));

    final row = await db.customSelect('SELECT * FROM sale_lines').getSingle();
    expect(row.read<int>('qty_milli'), 2000); // packages, as sold
    expect(row.read<String>('packaging_id'), 'pk1');
    expect(row.read<String>('unit_name'), 'Carton');
    expect(row.read<int>('quantity_base_milli'), 24000);
    expect(row.read<int>('base_qty_milli'), 48000);

    // Reading the sale back restores the packaging.
    final loaded = (await sales.load()).single;
    expect(loaded.cart.lines.single.packaging, carton);
    expect(loaded.cart.lines.single.baseQty, const Qty(48000));
    expect(diagnostics.hasFailures, isFalse);
  });

  test('a line without packaging is unchanged (null snapshot)', () async {
    final sale = ledgerSale(
      'AX000001',
      saleId: _id1,
      productIds: [prods[0].id],
      customerId: custs[1].id,
      customerName: custs[1].name,
    );
    await ledger.commit(checkoutOf(sale, 98));

    final row = await db.customSelect('SELECT * FROM sale_lines').getSingle();
    expect(row.read<String?>('packaging_id'), isNull);
    expect(row.read<int?>('base_qty_milli'), isNull);
    final uuid = products.snapshot[prods[0].id]!.uuid;
    expect((await inventory.balances('s1'))[uuid], 98000);
  });

  test('refunding 1 carton puts 24 pieces back', () async {
    await addCartonRow();
    final sale = cartonSale('AX000001', _id1, const Qty(2000));
    await ledger.commit(checkoutOf(sale, 52));

    final key = sale.cart.lines.first.key;
    final outcome = await ledger.applyRefund(
      RefundCommit(
        request: RefundRequest(
          saleNumber: sale.number,
          entries: {key: const Qty(1000)},
        ),
        sales: [
          sale.copyWith(returned: {key: const Qty(1000)}),
        ],
        products: [prods[0].copyWith(stock: 76), prods[1], prods[2]],
      ),
    );

    expect(outcome, PersistOutcome.saved);
    final uuid = products.snapshot[prods[0].id]!.uuid;
    expect((await inventory.balances('s1'))[uuid], 76000);
    final ret = (await inventory.transactions(
      's1',
    )).where((t) => t.reason.code == 'return').single;
    expect(ret.deltaMilli, 24000);
    // The packaged key is stored in the refund order and read back (DEC-154).
    final order = (await db.select(db.saleEntries).getSingle()).returnedOrder;
    expect(order, '["${key.text}"]');
    final back = (await sales.load()).single;
    expect(back.returned, {key: const Qty(1000)});
  });

  test('a failure rolls the whole packaged sale back', () async {
    await addCartonRow();
    await db.customStatement(
      'CREATE TRIGGER fail_inv BEFORE INSERT ON inventory_transactions '
      "BEGIN SELECT RAISE(ABORT, 'injected'); END",
    );

    final outcome = await ledger.commit(
      checkoutOf(cartonSale('AX000001', _id1, const Qty(2000)), 52),
    );

    expect(outcome, PersistOutcome.failed);
    for (final t in ['sales', 'sale_lines', 'inventory_transactions']) {
      expect(
        (await db.customSelect('SELECT COUNT(*) AS n FROM $t').getSingle())
            .read<int>('n'),
        0,
        reason: t,
      );
    }
    expect(await inventory.balances('s1'), isEmpty);
    final stock = await db
        .customSelect('SELECT stock FROM products ORDER BY position')
        .get();
    expect(stock.map((r) => r.read<int>('stock')), [100, 100, 100]);
  });

  test('a carton sale past the balance is blocked in base units', () async {
    await addCartonRow();
    await db.customStatement('UPDATE products SET stock = 40');
    await products.load();

    // 2 cartons = 48 pieces, only 40 on hand.
    final outcome = await ledger.commit(
      checkoutOf(cartonSale('AX000001', _id1, const Qty(2000)), -8),
    );

    expect(outcome, PersistOutcome.failed);
    expect(
      diagnostics.failures.map((f) => f.error.toString()).join(),
      contains('StockBlockedException'),
    );
  });
}
