// D6 (DEC-130): the cart draft in Drift: one row, the same write-behind, the same silent reset,
// the same mirror; plus the interactions with held bills and with checkout clearing the cart.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/config/app_config.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/database/migration/cart_rows.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/customers/controllers/customers_controller.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/customers/repository/customer_repository.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/held_bills_controller.dart';
import 'package:pos_application/modules/pos/controllers/hold_recall_controller.dart';
import 'package:pos_application/modules/pos/controllers/payment_controller.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/payment_state.dart';
import 'package:pos_application/modules/pos/repository/drift_cart_repository.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';

import '../../support/product_fixtures.dart';
import '../../support/test_app.dart';
import '../../support/test_infrastructure.dart';
import '../../support/test_tax.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  AxpertDatabase? db;

  @override
  Future<AxpertDatabase> open() async =>
      db ?? (throw StateError('database unavailable'));

  @override
  Future<void> close() async {}
}

class _NoCustomers implements CustomerRepository {
  @override
  Future<List<Customer>> load() async => <Customer>[];

  @override
  Future<void> save(List<Customer> customers) async {}
}

/// A store whose writes to [failKey] can be made to fail.
class _FlakyStore extends InMemoryLocalStore {
  String? failKey;

  @override
  Future<void> write(String key, Object? json) async {
    if (key == failKey) throw StateError('store unavailable');
    return super.write(key, json);
  }
}

void main() {
  useTestApp();
  late AxpertDatabase db;
  late _FlakyStore store;
  late StartupDiagnostics diagnostics;
  var clock = 0;

  setUp(() {
    MockDelay.provider = () => Duration.zero;
    db = AxpertDatabase(NativeDatabase.memory());
    store = _FlakyStore();
    diagnostics = StartupDiagnostics();
    clock = 0;
  });
  tearDown(() => db.close());

  DriftCartRepository repo(AxpertDatabase? database) => DriftCartRepository(
    provider: _Provider(database),
    store: store,
    diagnostics: diagnostics,
    now: () => DateTime.utc(2026, 10, 12, 0, 0, clock++),
  );

  Future<List<CurrentCartEntry>> rows() =>
      db.select(db.currentCartEntries).get();

  Cart cartOf(int id, {int qty = 1}) =>
      Cart.empty.addItem(prod(id)).setQty(id, Qty.units(qty));

  test('first load is the empty cart and writes a marker, no row', () async {
    final cart = await repo(db).load();

    expect(cart.lines, isEmpty);
    expect(await rows(), isEmpty);
    expect(await db.select(db.migrationStateEntries).get(), hasLength(1));
    expect(await store.has(StorageKeys.cart), isFalse);
  });

  test('save writes the one row and the same JSON to the mirror', () async {
    final repository = repo(db);
    await repository.load();

    await repository.save(cartOf(1, qty: 2));

    final r = await rows();
    expect(r.single.id, 1);
    expect(r.single.cartJson, CartRows.encode(cartOf(1, qty: 2)));
    expect(await store.read(StorageKeys.cart), cartOf(1, qty: 2).toJson());
    expect((await repo(db).load()).toJson(), cartOf(1, qty: 2).toJson());
  });

  test('saving the same cart twice writes once', () async {
    final repository = repo(db);
    await repository.load();

    await repository.save(cartOf(1));
    final stamp = clock;
    await repository.save(cartOf(1));
    await repository.save(Cart.fromJson(cartOf(1).toJson()));

    expect(clock, stamp, reason: 'no further write');
    expect(await rows(), hasLength(1));
  });

  test('a changed cart overwrites the same row', () async {
    final repository = repo(db);
    await repository.load();
    await repository.save(cartOf(1));
    await repository.save(cartOf(2));
    await repository.save(Cart.empty);

    final r = await rows();
    expect(r, hasLength(1));
    expect(r.single.cartJson, CartRows.encode(Cart.empty));
  });

  test('a burst through the controller is at most two Drift writes', () async {
    final repository = repo(db);
    final cart = CartController(
      repository,
      CustomersController(_NoCustomers()),
      pricing: testIndiaPricing,
    );
    await cart.load();
    final before = clock;

    cart.addItem(prod(1));
    for (var i = 0; i < 30; i++) {
      cart.setQty(1, Qty(1000 + i));
    }
    await cart.flush();

    expect(clock - before, lessThanOrEqualTo(2));
    expect((await repo(db).load()).lines.single.qty, const Qty(1029));
    expect(await store.read(StorageKeys.cart), cart.cart.value.toJson());
  });

  test(
    'an unreadable row resets silently, is recorded, and is overwritten',
    () async {
      await repo(db).load();
      await db.customStatement(
        "INSERT INTO current_cart (cart_json, updated_at) VALUES ('{bad', 0)",
      );
      final repository = repo(db);

      final cart = await repository.load();

      expect(cart.lines, isEmpty);
      expect(diagnostics.failures.single.stage, 'cart unreadable');
      await repository.save(cartOf(3));
      expect((await repo(db).load()).lines.single.product.id, 3);
    },
  );

  test(
    'an unreadable LocalStore cart on the first start is reported, empty',
    () async {
      await store.write(StorageKeys.cart, 'garbage');

      final cart = await repo(db).load();

      expect(cart.lines, isEmpty);
      expect(diagnostics.failures.single.stage, 'cart copy report');
      expect(await rows(), isEmpty);
    },
  );

  test(
    'fallback session marks stale; restart re-copies the newer cart',
    () async {
      final seed = repo(db);
      await seed.load();
      await seed.save(cartOf(1));
      final failing = repo(null);

      await failing.load();
      await failing.save(cartOf(2));

      expect(diagnostics.hasFailures, isTrue);
      expect(await store.read(StorageKeys.cartDriftStale), true);
      expect((await rows()).single.cartJson, CartRows.encode(cartOf(1)));

      final restarted = await repo(db).load();

      expect(restarted.lines.single.product.id, 2);
      expect(await store.has(StorageKeys.cartDriftStale), isFalse);
      expect((await rows()).single.cartJson, CartRows.encode(cartOf(2)));
    },
  );

  test('localStore backend session, then switch back to Drift', () async {
    final seed = repo(db);
    await seed.load();
    await seed.save(cartOf(1));
    final rollback = LocalStoreCartRepository(store);

    expect((await rollback.load()).lines.single.product.id, 1);
    await rollback.save(cartOf(4));

    expect(await store.read(StorageKeys.cartDriftStale), true);
    expect((await rows()).single.cartJson, CartRows.encode(cartOf(1)));

    final back = await repo(db).load();

    expect(back.lines.single.product.id, 4);
    expect(await store.has(StorageKeys.cartDriftStale), isFalse);
  });

  test('Drift save failure falls back to LocalStore and marks stale', () async {
    final repository = repo(db);
    await repository.load();
    await db.customStatement('DROP TABLE current_cart');

    await repository.save(cartOf(5));

    expect(await store.read(StorageKeys.cart), cartOf(5).toJson());
    expect(await store.read(StorageKeys.cartDriftStale), true);
    expect(diagnostics.hasFailures, isTrue);
  });

  test('a failed copy verification keeps LocalStore authoritative', () async {
    await store.write(StorageKeys.cart, cartOf(6).toJson());
    await db.customStatement(
      'CREATE TRIGGER t AFTER INSERT ON current_cart BEGIN '
      "UPDATE current_cart SET cart_json = 'garbage'; END",
    );

    final cart = await repo(db).load();

    expect(cart.lines.single.product.id, 6, reason: 'read from LocalStore');
    expect(await rows(), isEmpty);
    expect(await store.read(StorageKeys.cartDriftStale), true);
  });

  test('a failed mirror write is retried by the next identical save', () async {
    final repository = repo(db);
    await repository.load();
    store.failKey = StorageKeys.cart;
    await repository.save(cartOf(1));
    expect(diagnostics.failures.last.stage, 'cart dual-write');
    expect(repository.lastJson, isNull);

    store.failKey = null;
    await repository.save(cartOf(1));

    expect(await store.read(StorageKeys.cart), cartOf(1).toJson());
    expect(repository.lastJson, CartRows.encode(cartOf(1)));
  });

  group('with held bills, checkout and the other Drift stores', () {
    Future<void> boot() => bootTestApp(
      store: store,
      infrastructure: testInfrastructure(
        databaseProvider: _Provider(db),
        customersBackend: CustomersBackend.drift,
        productsBackend: ProductsBackend.drift,
        salesBackend: SalesBackend.drift,
        heldBackend: HeldBackend.drift,
        cartBackend: CartBackend.drift,
      ),
    );

    Future<void> until(Future<bool> Function() done) async {
      for (var i = 0; i < 100 && !await done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    Future<Cart> storedCart() async => (await CartRows.read(db)).cart;

    Future<int> heldRows({required bool active}) async =>
        (await db
                .customSelect(
                  'SELECT COUNT(*) AS n FROM held_bills WHERE deleted_at IS '
                  '${active ? '' : 'NOT '}NULL',
                )
                .getSingle())
            .read<int>('n');

    test('a cart change lands in Drift and the mirror', () async {
      await boot();
      Get.find<CartActionsController>().add(
        Get.find<ProductsController>().byId(5)!,
      );
      await Get.find<CartController>().flush();

      expect((await storedCart()).lines.single.product.id, 5);
      expect(
        (await store.read(StorageKeys.cart) as Map)['lines'],
        hasLength(1),
      );
    });

    test('hold: the bill is a held row and the cart row is empty', () async {
      await boot();
      Get.find<CartActionsController>().add(
        Get.find<ProductsController>().byId(5)!,
      );
      await Get.find<CartController>().flush();

      Get.find<HoldRecallController>().hold();
      await until(() async => (await storedCart()).lines.isEmpty);
      await until(() async => await heldRows(active: true) == 1);

      expect(await heldRows(active: true), 1);
      expect((await storedCart()).lines, isEmpty);
    });

    test('hold when the cart write cannot land: the bill is in held AND '
        'the persisted cart (safe duplicate on restart)', () async {
      await boot();
      Get.find<CartActionsController>().add(
        Get.find<ProductsController>().byId(5)!,
      );
      await Get.find<CartController>().flush();
      await db.customStatement(
        'CREATE TRIGGER block_cart BEFORE UPDATE ON current_cart '
        "BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );

      Get.find<HoldRecallController>().hold();
      await until(() async => await heldRows(active: true) == 1);
      await Get.find<CartController>().flush();

      expect(await heldRows(active: true), 1);
      expect(
        (await storedCart()).lines,
        hasLength(1),
        reason: 'the cart row kept the old cart',
      );
      // The failed cart write fell back to LocalStore and marked Drift stale.
      expect(await store.read(StorageKeys.cartDriftStale), true);
      expect((await store.read(StorageKeys.cart) as Map)['lines'], isEmpty);
    });

    test(
      'recall: the cart row holds the recalled cart and the bill is a tombstone',
      () async {
        await boot();
        Get.find<CartActionsController>().add(
          Get.find<ProductsController>().byId(5)!,
        );
        final hold = Get.find<HoldRecallController>();
        hold.hold();
        await until(() async => await heldRows(active: true) == 1);
        hold.recall(Get.find<HeldBillsController>().bills.single);
        await Get.find<CartController>().flush();
        await until(() async => await heldRows(active: false) == 1);

        expect((await storedCart()).lines.single.product.id, 5);
        expect(await heldRows(active: true), 0);
        expect(await heldRows(active: false), 1);
      },
    );

    test('checkout clears the persisted cart after the commit', () async {
      await boot();
      Get.find<CartActionsController>().add(
        Get.find<ProductsController>().byId(5)!,
      );
      await Get.find<CartController>().flush();
      final pay = Get.find<PaymentController>();
      pay.payment(PaymentMode.cash);

      pay.completeCash();
      await until(() async => (await storedCart()).lines.isEmpty);
      await until(
        () async =>
            (await db
                    .customSelect('SELECT COUNT(*) AS n FROM sales')
                    .getSingle())
                .read<int>('n') ==
            1,
      );

      expect((await storedCart()).lines, isEmpty);
      expect(Get.find<SalesController>().sales, hasLength(1));
    });

    test(
      'checkout when the cart row cannot be cleared: the sale is saved and the '
      'persisted cart still holds the sold items (safe direction)',
      () async {
        await boot();
        Get.find<CartActionsController>().add(
          Get.find<ProductsController>().byId(5)!,
        );
        await Get.find<CartController>().flush();
        await db.customStatement(
          'CREATE TRIGGER block_cart BEFORE UPDATE ON current_cart '
          "BEGIN SELECT RAISE(ABORT, 'injected'); END",
        );
        final pay = Get.find<PaymentController>();
        pay.payment(PaymentMode.cash);

        pay.completeCash();
        await until(
          () async =>
              (await db
                      .customSelect('SELECT COUNT(*) AS n FROM sales')
                      .getSingle())
                  .read<int>('n') ==
              1,
        );
        await Get.find<CartController>().flush();

        expect(
          (await db.customSelect('SELECT COUNT(*) AS n FROM sales').getSingle())
              .read<int>('n'),
          1,
        );
        expect((await storedCart()).lines, hasLength(1));
      },
    );
  });
}
