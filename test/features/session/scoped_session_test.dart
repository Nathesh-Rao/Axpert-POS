// The whole stack on the seeded database (DEC-132): sign in, store and counter,
// scoped data, the store's currency, a checkout stamped with the session, and a
// second store with its own currency.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/bindings/initial_binding.dart';
import 'package:pos_application/core/config/app_config.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/audio/audio_service.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/core/utils/money_formatter.dart';
import 'package:pos_application/features/offers/presentation/controllers/offers_controller.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/features/session/presentation/controllers/active_session.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/held_bills_controller.dart';
import 'package:pos_application/modules/pos/controllers/payment_controller.dart';
import 'package:pos_application/modules/pos/models/payment_state.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';
import 'package:pos_application/modules/shift/controllers/shift_controller.dart';

import '../../support/seeded_database.dart';
import '../../support/test_infrastructure.dart';

Future<ActiveSession> _boot(AxpertDatabase db) async {
  MockDelay.provider = () => Duration.zero;
  Get.reset();
  final binding = InitialBinding(
    InMemoryLocalStore(),
    infrastructure: testInfrastructure(
      databaseProvider: FixedDatabaseProvider(db),
      settingsBackend: SettingsBackend.drift,
      customersBackend: CustomersBackend.drift,
      heldBackend: HeldBackend.drift,
      productsBackend: ProductsBackend.drift,
      salesBackend: SalesBackend.drift,
      cartBackend: CartBackend.drift,
    ),
    audio: RecordingAudioService(),
  );
  binding.dependencies();
  await binding.loadData();
  return Get.find<ActiveSession>();
}

void main() {
  late AxpertDatabase db;
  setUp(() async => db = await seededDatabase());
  tearDown(() async {
    Get.reset();
    await db.close();
  });

  test('scoped data stays empty until a store is opened', () async {
    await _boot(db);
    expect(Get.find<ProductsController>().products, isEmpty);
    expect(Get.find<SalesController>().sales, isEmpty);
  });

  test(
    'a wrong password or user fails the same way, a right one signs in',
    () async {
      final session = await _boot(db);
      final wrong = await session.signIn('cashier1', 'nope');
      expect(wrong.failure, SignInFailure.invalid);
      final unknown = await session.signIn('ghost', 'Demo#Cashier1');
      expect(unknown.failure, SignInFailure.invalid);
      expect(session.isSignedIn, isFalse);
      final ok = await session.signIn('cashier1', 'Demo#Cashier1');
      expect(ok.ok, isTrue);
      expect(session.onlyChoice, isNotNull, reason: 'one store, one counter');
    },
  );

  test(
    'cashier1 opens Ozone: its catalog, offers and rupee formatting',
    () async {
      final session = await _boot(db);
      await session.signIn('cashier1', 'Demo#Cashier1');
      final (store, counter) = session.onlyChoice!;
      await session.begin(store, counter);
      final products = Get.find<ProductsController>();
      expect(products.products, hasLength(32));
      expect(Get.find<SalesController>().sales, hasLength(18));
      expect(Get.find<OffersController>().offers, hasLength(7));
      expect(session.currency!.code, 'INR');
      final cola = products.products.firstWhere((p) => p.code == 'BDV001');
      expect(MoneyFormatter.format(cola.price), '₹40.00');
      expect(session.quickCash, [100, 500, 2000]);
      expect(counter!.name, 'C1');
    },
  );

  test('a checkout is stamped with store, counter and cashier', () async {
    final session = await _boot(db);
    await session.signIn('cashier1', 'Demo#Cashier1');
    final (store, counter) = session.onlyChoice!;
    await session.begin(store, counter);
    final products = Get.find<ProductsController>();
    Get.find<CartActionsController>().add(
      products.products.firstWhere((p) => p.code == 'NOD001'),
    );
    final cart = Get.find<CartController>();
    expect(cart.cart.value.storeId, store.id);
    final pay = Get.find<PaymentController>();
    pay.payment(PaymentMode.cash);
    pay.tendered.text = '500';
    pay.completeCash();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final sales = Get.find<SalesController>().sales;
    expect(sales, hasLength(19));
    expect(sales.last.number, 'AX000019');
    expect(sales.last.cashier, 'Chitra Cashier');
    final row = await db
        .customSelect(
          "SELECT store_id, counter_id, user_id, user_name, currency_code "
          "FROM sales WHERE number = 'AX000019' AND store_id = '${store.id}'",
        )
        .getSingle();
    expect(row.read<String>('store_id'), store.id);
    expect(row.read<String>('counter_id'), counter!.id);
    expect(row.read<String>('user_id'), 'demo-user-cashier1');
    expect(row.read<String>('user_name'), 'Chitra Cashier');
    expect(row.read<String>('currency_code'), 'INR');
    // The other store's sales are untouched.
    final other = await db
        .customSelect(
          "SELECT COUNT(*) AS n FROM sales WHERE store_id = 'demo-store-kampala'",
        )
        .getSingle();
    expect(other.read<int>('n'), 12);
  });

  test('admin switches to Kampala: its own currency and catalog', () async {
    final session = await _boot(db);
    await session.signIn('admin', 'Demo#Admin1');
    expect(session.onlyChoice, isNull, reason: 'two stores need the picker');
    final ozone = session.access.first;
    await session.begin(ozone.store, ozone.counters.first);
    expect(session.currency!.symbol, '₹');
    final kampala = session.access.last;
    await session.switchStore(kampala.store);
    final products = Get.find<ProductsController>();
    expect(products.products, hasLength(28));
    expect(session.currency!.code, 'UGX');
    expect(session.currency!.exponent, 0);
    final cola = products.products.firstWhere((p) => p.code == 'BDV001');
    expect(cola.price.currency.code, 'UGX');
    expect(MoneyFormatter.format(cola.price), 'USh 1,800');
    expect(Get.find<SalesController>().sales, hasLength(12));
    expect(Get.find<OffersController>().offers, hasLength(6));
    expect(Get.find<HeldBillsController>().bills, isEmpty);
    // Pricing is in shillings, with no minor unit.
    Get.find<CartActionsController>().add(cola);
    final total = Get.find<CartController>().totals.value.total;
    expect(total.currency.code, 'UGX');
    expect(MoneyFormatter.format(total), startsWith('USh '));
    expect(session.quickCash, [5000, 20000, 100000]);
    // The shift summary is in the store's currency too.
    expect(Get.find<ShiftController>().today.total.currency.code, 'UGX');
  });

  test('a saved cart of another store is dropped at sign-in', () async {
    final session = await _boot(db);
    await session.signIn('admin', 'Demo#Admin1');
    final ozone = session.access.first;
    await session.begin(ozone.store, ozone.counters.first);
    final cola = Get.find<ProductsController>().products.firstWhere(
      (p) => p.code == 'BDV001',
    );
    Get.find<CartActionsController>().add(cola);
    await Get.find<CartController>().flush();
    // New boot (restart), sign in to the other store.
    final again = await _boot(db);
    await again.signIn('admin', 'Demo#Admin1');
    final kampala = again.access.last;
    await again.begin(kampala.store, kampala.counters.first);
    expect(Get.find<CartController>().cart.value.isActive, isFalse);
  });

  test('a saved cart of the same store comes back with its currency', () async {
    final session = await _boot(db);
    await session.signIn('admin', 'Demo#Admin1');
    final kampala = session.access.last;
    await session.begin(kampala.store, kampala.counters.first);
    final cola = Get.find<ProductsController>().products.firstWhere(
      (p) => p.code == 'BDV001',
    );
    Get.find<CartActionsController>().add(cola);
    await Get.find<CartController>().flush();
    final again = await _boot(db);
    await again.signIn('admin', 'Demo#Admin1');
    final k2 = again.access.last;
    await again.begin(k2.store, k2.counters.first);
    final cart = Get.find<CartController>().cart.value;
    expect(cart.lines, hasLength(1));
    expect(cart.lines.single.price.currency.code, 'UGX');
  });
}
