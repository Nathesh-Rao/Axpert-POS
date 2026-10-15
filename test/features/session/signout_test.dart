// DEC-150: the one sign-out on the seeded database. Memory is emptied, saved
// data stays, and the next user starts clean: no stale role, store, counter or
// cart lines of the previous user.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/bindings/initial_binding.dart';
import 'package:pos_application/core/config/app_config.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/audio/audio_service.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/core/session/session_controller.dart';
import 'package:pos_application/features/offers/presentation/controllers/offers_controller.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/features/session/presentation/controllers/active_session.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/held_bills_controller.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';
import 'package:pos_application/modules/settings/controllers/database_export_controller.dart';
import 'package:pos_application/modules/shift/controllers/shift_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';

import '../../support/held_fixtures.dart';
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

Future<void> _open(ActiveSession session, String user, String pass) async {
  final result = await session.signIn(user, pass);
  expect(result.ok, isTrue);
  final (store, counter) = session.onlyChoice ?? _first(session);
  await session.begin(store, counter);
}

(dynamic, dynamic) _first(ActiveSession session) {
  final entry = session.access.first;
  return (entry.store, entry.counters.first);
}

Future<int> _count(AxpertDatabase db, String sql) async =>
    (await db.customSelect(sql).getSingle()).read<int>('n');

void main() {
  late AxpertDatabase db;
  setUp(() async => db = await seededDatabase());
  tearDown(() async {
    Get.reset();
    await db.close();
  });

  test('sign-out clears the session and the in-memory state', () async {
    final session = await _boot(db);
    await _open(session, 'cashier1', 'Demo#Cashier1');
    expect(Get.find<ProductsController>().products, isNotEmpty);
    Get.find<OverlayController>().open('settings');
    Get.find<ShiftController>().signedOut.value = true;

    await session.signOut();

    expect(session.isSignedIn, isFalse);
    expect(session.store.value, isNull);
    expect(session.counter.value, isNull);
    expect(session.access, isEmpty);
    expect(session.scoped, isFalse);
    expect(Get.find<ProductsController>().products, isEmpty);
    expect(Get.find<SalesController>().sales, isEmpty);
    expect(Get.find<OffersController>().offers, isEmpty);
    expect(Get.find<HeldBillsController>().bills, isEmpty);
    expect(Get.find<CartController>().isActive, isFalse);
    expect(Get.find<OverlayController>().modal.value, isNull);
    expect(Get.find<ShiftController>().signedOut.value, isFalse);
  });

  test('hooks: the cart is flushed first, the reset runs last, once', () async {
    final session = await _boot(db);
    await _open(session, 'cashier1', 'Demo#Cashier1');
    final order = <String>[];
    final before = session.beforeSignOut!;
    final after = session.onSignedOut!;
    session.beforeSignOut = () async {
      order.add('before, user ${session.user.value?.username}');
      await before();
    };
    session.onSignedOut = () {
      order.add('after, user ${session.user.value?.username}');
      after();
    };

    await session.signOut();
    await session.signOut(); // already signed out: nothing runs again

    expect(order, <String>['before, user cashier1', 'after, user null']);
  });

  test('sign-out also signs out the authentication service seam', () async {
    final session = await _boot(db);
    await _open(session, 'cashier1', 'Demo#Cashier1');
    final controller = Get.find<SessionController>();
    controller.session.value = null;

    await session.signOut();

    expect(controller.status.value, SessionStatus.unauthenticated);
  });

  test('saved data stays: held bills and the in-progress cart', () async {
    final session = await _boot(db);
    await _open(session, 'cashier1', 'Demo#Cashier1');
    await Get.find<HeldBillsController>().add(heldBill('000001'));
    final products = Get.find<ProductsController>();
    Get.find<CartActionsController>().add(
      products.products.firstWhere((p) => p.code == 'NOD001'),
    );
    final held = await _count(
      db,
      'SELECT COUNT(*) AS n FROM held_bills WHERE deleted_at IS NULL',
    );
    final sales = await _count(db, 'SELECT COUNT(*) AS n FROM sales');

    await session.signOut();

    expect(
      await _count(
        db,
        'SELECT COUNT(*) AS n FROM held_bills WHERE deleted_at IS NULL',
      ),
      held,
    );
    expect(held, greaterThan(0));
    expect(await _count(db, 'SELECT COUNT(*) AS n FROM sales'), sales);
    // The cart was written before the memory was emptied.
    expect(await _count(db, 'SELECT COUNT(*) AS n FROM current_cart'), 1);
    final row = await db
        .customSelect('SELECT cart_json FROM current_cart')
        .getSingle();
    expect(row.read<String>('cart_json'), contains('NOD001'));
  });

  test('cashier then admin: no stale role, store, counter or cart', () async {
    final session = await _boot(db);
    await _open(session, 'cashier1', 'Demo#Cashier1');
    final export = Get.find<DatabaseExportController>();
    expect(session.user.value!.role, 'cashier');
    expect(export.canExport, isFalse);
    final cashierStore = session.store.value!.id;

    await session.signOut();
    expect(export.canExport, isFalse);
    expect(session.user.value, isNull);

    final admin = await session.signIn('admin', 'Demo#Admin1');
    expect(admin.ok, isTrue);
    expect(session.user.value!.username, 'admin');
    expect(session.user.value!.role, 'admin');
    expect(export.canExport, isTrue);
    expect(session.store.value, isNull, reason: 'the picker comes first');
    await session.begin(
      session.access.first.store,
      session.access.first.counters.first,
    );
    expect(session.store.value!.id, cashierStore); // Ozone is first for both
    expect(session.displayName, isNot('Chitra Cashier'));
    expect(Get.find<CartController>().isActive, isFalse);
    expect(Get.find<ProductsController>().products, isNotEmpty);
  });

  test(
    'an in-progress cart is kept for the same store and dropped for another',
    () async {
      final session = await _boot(db);
      await _open(session, 'cashier1', 'Demo#Cashier1');
      final products = Get.find<ProductsController>();
      Get.find<CartActionsController>().add(
        products.products.firstWhere((p) => p.code == 'NOD001'),
      );
      await session.signOut();
      expect(Get.find<CartController>().isActive, isFalse);

      // Today's rule: the device-wide saved cart returns for the same store...
      await session.signIn('admin', 'Demo#Admin1');
      await session.begin(
        session.access.first.store,
        session.access.first.counters.first,
      );
      expect(Get.find<CartController>().isActive, isTrue);
      await Get.find<CartController>().flush();
      await session.signOut();

      // ...and is dropped when another store opens.
      await session.signIn('admin', 'Demo#Admin1');
      final other = session.access.last;
      await session.begin(other.store, other.counters.first);
      expect(Get.find<CartController>().isActive, isFalse);
    },
  );
}
