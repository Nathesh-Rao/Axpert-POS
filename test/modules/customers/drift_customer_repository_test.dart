import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/config/app_config.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/customers/controllers/customers_controller.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/customers/repository/drift_customer_repository.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_meta_controller.dart';
import 'package:pos_application/modules/pos/controllers/member_controller.dart';
import 'package:pos_application/modules/pos/controllers/payment_controller.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';

import '../../support/test_app.dart';
import '../../support/test_infrastructure.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  AxpertDatabase? db;

  @override
  Future<AxpertDatabase> open() async =>
      db ?? (throw StateError('database unavailable'));

  @override
  Future<void> close() async {}
}

Customer _c(String id, String name, {int points = 0}) => Customer(
  id: id,
  name: name,
  phone: '9876543210',
  email: '',
  member: 'MG$id',
  points: points,
);

void main() {
  useTestApp();
  late AxpertDatabase db;
  late InMemoryLocalStore store;
  late StartupDiagnostics diagnostics;

  setUp(() {
    MockDelay.provider = () => Duration.zero;
    db = AxpertDatabase(NativeDatabase.memory());
    store = InMemoryLocalStore();
    diagnostics = StartupDiagnostics();
  });
  tearDown(() => db.close());

  DriftCustomerRepository repo(AxpertDatabase? database) =>
      DriftCustomerRepository(
        provider: _Provider(database),
        store: store,
        diagnostics: diagnostics,
        uuid: UuidV4Generator(),
      );

  Future<int> driftPoints(String legacyId) async {
    final row = await (db.select(
      db.customerEntries,
    )..where((t) => t.legacyId.equals(legacyId))).getSingle();
    return row.points;
  }

  Future<int> storePoints(String id) async {
    final list = await store.read(StorageKeys.customers) as List<dynamic>;
    return (list.firstWhere((e) => (e as Map)['id'] == id) as Map)['points']
        as int;
  }

  test('first load copies the seed into Drift', () async {
    final loaded = await repo(db).load();

    expect(loaded.map((c) => c.id), ['walk', '1', '2', '3']);
    expect(await db.select(db.customerEntries).get(), hasLength(4));
    expect(await store.has(StorageKeys.customers), isFalse);
  });

  test('save writes Drift and dual-writes LocalStore', () async {
    final repository = repo(db);
    final list = await repository.load();
    final next = [...list, _c('9', 'New', points: 4)];

    await repository.save(next);

    expect(await driftPoints('9'), 4);
    expect(await storePoints('9'), 4);
    expect(await repo(db).load(), next);
  });

  test('duplicate ids at save are renamed and written back', () async {
    final repository = repo(db);
    final list = await repository.load();

    await repository.save([...list, _c('5', 'A'), _c('5', 'B')]);

    final again = await repo(db).load();
    expect(again.map((c) => c.id), ['walk', '1', '2', '3', '5', '5~dup2']);
    final raw = await store.read(StorageKeys.customers) as List<dynamic>;
    expect(raw.map((e) => (e as Map)['id']), contains('5~dup2'));
  });

  test('copy findings are recorded in diagnostics', () async {
    await store.write(StorageKeys.customers, [
      _c('1', 'A').toJson(),
      _c('1', 'B').toJson(),
    ]);

    await repo(db).load();

    expect(diagnostics.failures.single.stage, 'customers copy report');
  });

  test('fallback session marks stale; restart re-copies', () async {
    await repo(db).load();
    final failing = repo(null);

    final loaded = await failing.load();
    await failing.save([...loaded, _c('8', 'Fallback')]);

    expect(diagnostics.hasFailures, isTrue);
    expect(await store.read(StorageKeys.customersDriftStale), true);
    expect(await db.select(db.customerEntries).get(), hasLength(4));

    final restarted = await repo(db).load();

    expect(restarted.map((c) => c.id), ['walk', '1', '2', '3', '8']);
    expect(await store.has(StorageKeys.customersDriftStale), isFalse);
  });

  test('localStore backend session, then switch back to Drift', () async {
    final first = await repo(db).load();
    final rollback = LocalStoreCustomerRepository(store);

    final loaded = await rollback.load();
    expect(loaded, first);
    await rollback.save([
      for (final c in loaded) c.id == '1' ? _c('1', 'Renamed', points: 1) : c,
      _c('7', 'Added'),
    ]);

    expect(await store.read(StorageKeys.customersDriftStale), true);
    expect(await driftPoints('1'), 250);

    final back = await repo(db).load();

    expect(back.map((c) => c.id), ['walk', '1', '2', '3', '7']);
    expect(back[1].name, 'Renamed');
    expect(await driftPoints('1'), 1);
    expect(await store.has(StorageKeys.customersDriftStale), isFalse);
  });

  test('failed re-copy keeps LocalStore authoritative, key stays', () async {
    await repo(db).load();
    await store.write(StorageKeys.customersDriftStale, true);
    await store.write(StorageKeys.customers, [
      {'id': 'x'},
    ]);

    await expectLater(repo(db).load(), throwsA(isA<TypeError>()));

    expect(await store.has(StorageKeys.customersDriftStale), isTrue);
    expect(await driftPoints('1'), 250);
  });

  test('Drift save failure falls back to LocalStore and marks stale', () async {
    final repository = repo(db);
    final list = await repository.load();
    await db.customStatement('DROP TABLE customers');

    await repository.save([...list, _c('6', 'Late')]);

    expect(await storePoints('6'), 0);
    expect(await store.read(StorageKeys.customersDriftStale), true);
    expect(diagnostics.hasFailures, isTrue);
  });

  test(
    'overlapping unawaited saves end at the last value (Drift and LocalStore)',
    () async {
      final repository = repo(db);
      final list = await repository.load();
      List<Customer> withPoints(int points) => [
        for (final c in list) c.id == '1' ? _c('1', c.name, points: points) : c,
      ];

      final a = repository.save(withPoints(1));
      final b = repository.save(withPoints(2));
      final c = repository.save(withPoints(3));
      await Future.wait([a, b, c]);

      expect(await driftPoints('1'), 3);
      expect(await storePoints('1'), 3);
    },
  );

  test(
    'overlapping saves after a Drift failure stay in order and keep the stale key',
    () async {
      final repository = repo(db);
      final list = await repository.load();
      await db.customStatement('DROP TABLE customers');
      List<Customer> withPoints(int points) => [
        for (final c in list) c.id == '1' ? _c('1', c.name, points: points) : c,
      ];

      final a = repository.save(withPoints(1));
      final b = repository.save(withPoints(2));
      final c = repository.save(withPoints(3));
      await Future.wait([a, b, c]);

      expect(await storePoints('1'), 3);
      expect(await store.read(StorageKeys.customersDriftStale), true);
    },
  );

  group('checkout points deduction with Drift customers', () {
    Future<void> boot(DatabaseProvider provider) async {
      await bootTestApp(
        store: store,
        infrastructure: testInfrastructure(
          databaseProvider: provider,
          customersBackend: CustomersBackend.drift,
        ),
      );
    }

    Future<void> checkout() async {
      Get.find<CartActionsController>().add(
        Get.find<ProductsController>().byId(5)!,
      );
      Get.find<CartMetaController>().setCustomer('1');
      Get.find<MemberController>().setPoints('5');
      final pay = Get.find<PaymentController>();
      pay.tendered.text = '100';
      pay.completeCash();
      final sales = Get.find<SalesController>();
      for (var i = 0; i < 100 && sales.sales.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(sales.sales, hasLength(1));
    }

    test(
      'memory is authoritative at once; Drift and LocalStore follow',
      () async {
        await boot(_Provider(db));
        final customers = Get.find<CustomersController>();
        expect(customers.customers[1].points, 250);

        await checkout();

        // Checked before awaiting the persistence future.
        expect(customers.customers[1].points, 245);
        for (var i = 0; i < 100 && await driftPoints('1') != 245; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        expect(await driftPoints('1'), 245);
        expect(await storePoints('1'), 245);
        expect(await store.has(StorageKeys.customersDriftStale), isFalse);
      },
    );

    test(
      'a failing Drift save changes nothing in memory or the sale',
      () async {
        final provider = _Provider(db);
        await boot(provider);
        final customers = Get.find<CustomersController>();
        await db.customStatement('DROP TABLE customers');

        await checkout();

        expect(customers.customers[1].points, 245);
        for (var i = 0; i < 100 && await storePoints('1') != 245; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        expect(await storePoints('1'), 245);
        expect(await store.read(StorageKeys.customersDriftStale), true);
        expect(
          Get.find<SalesController>().sales.single.customer,
          'Ananya Sharma',
        );
      },
    );
  });

  test('copy marker report is stored as JSON', () async {
    await repo(db).load();
    final row = await (db.select(db.migrationStateEntries)).get();
    final marker =
        jsonDecode(row.firstWhere((r) => r.key == 'customers_copy_v1').value)
            as Map<String, dynamic>;
    expect(marker['count'], 4);
    expect((marker['report'] as Map)['renamed'], isEmpty);
  });
}
