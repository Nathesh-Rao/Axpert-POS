import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/core/services/storage/local_store.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/customers/repository/customer_repository.dart';
import 'package:pos_application/modules/customers/repository/drift_customer_repository.dart';
import 'package:pos_application/modules/customers/repository/mock_customer_repository.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  final AxpertDatabase db;

  @override
  Future<AxpertDatabase> open() async => db;

  @override
  Future<void> close() async {}
}

/// One backend under test: [create] builds a repository over the shared
/// [store] (a new call is a "restart" on the same persisted data).
class _Backend {
  _Backend(this.create, [this.dispose]);

  final CustomerRepository Function(LocalStore store) create;
  final Future<void> Function()? dispose;
}

_Backend _mock() => _Backend(MockCustomerRepository.new);

_Backend _drift() {
  final db = AxpertDatabase(NativeDatabase.memory());
  return _Backend(
    (store) => DriftCustomerRepository(
      provider: _Provider(db),
      store: store,
      diagnostics: StartupDiagnostics(),
      uuid: UuidV4Generator(),
    ),
    db.close,
  );
}

Customer _c(String id, String name, {int points = 0}) => Customer(
  id: id,
  name: name,
  phone: '9876543210',
  email: 'x@y.co',
  member: 'MG$id',
  points: points,
);

List<String> _ids(List<Customer> list) => [for (final c in list) c.id];

void main() {
  setUp(() => MockDelay.provider = () => Duration.zero);

  final backends = <String, _Backend Function()>{
    'Mock': _mock,
    'Drift (in-memory)': _drift,
  };
  for (final entry in backends.entries) {
    final make = entry.value;
    group('CustomerRepository contract: ${entry.key}', () {
      late _Backend backend;
      late InMemoryLocalStore store;

      setUp(() {
        backend = make();
        store = InMemoryLocalStore();
      });
      tearDown(() async => backend.dispose?.call());

      test('first load returns the 4 seed customers in order', () async {
        final loaded = await backend.create(store).load();

        expect(_ids(loaded), ['walk', '1', '2', '3']);
        expect(loaded[1].name, 'Ananya Sharma');
        expect(loaded[1].points, 250);
        expect(await backend.create(store).load(), loaded);
      });

      test('save then load on a new instance round-trips in order', () async {
        final list = [_c('9', 'Zed', points: 5), _c('4', 'Amy'), _c('7', 'Bo')];
        final first = backend.create(store);
        await first.load();
        await first.save(list);

        expect(await backend.create(store).load(), list);
      });

      test('app add (append at the end) keeps the exact order', () async {
        final repo = backend.create(store);
        var list = await repo.load();
        // CustomersController.add: `customers.add(customer)` then save.
        for (final id in ['1700000000001', '1700000000002', '1700000000003']) {
          list = [...list, _c(id, 'N$id')];
          await repo.save(list);
          expect(await backend.create(store).load(), list);
        }

        expect(_ids(await backend.create(store).load()), [
          'walk',
          '1',
          '2',
          '3',
          '1700000000001',
          '1700000000002',
          '1700000000003',
        ]);
      });

      test('points deduction replaces in place, order unchanged', () async {
        final repo = backend.create(store);
        final list = await repo.load();
        // CustomersController.deductPoints: same index, points - n.
        final next = [
          for (final c in list)
            c.id == '2'
                ? Customer(
                    id: c.id,
                    name: c.name,
                    phone: c.phone,
                    email: c.email,
                    member: c.member,
                    points: c.points - 20,
                  )
                : c,
        ];
        await repo.save(next);

        final again = await backend.create(store).load();
        expect(_ids(again), ['walk', '1', '2', '3']);
        expect(again[2].points, 100);
      });

      test('a reordered or shortened list reloads exactly as saved', () async {
        final repo = backend.create(store);
        final list = await repo.load();
        final reordered = [list[3], list[0], list[2]];
        await repo.save(reordered);
        expect(await backend.create(store).load(), reordered);

        final added = [...reordered, _c('55', 'Back')];
        await repo.save(added);
        expect(await backend.create(store).load(), added);

        final restored = [list[1], ...added];
        await repo.save(restored);
        expect(_ids(await backend.create(store).load()), [
          '1',
          '3',
          'walk',
          '2',
          '55',
        ]);
      });

      test('a stored [] stays empty (not re-seeded)', () async {
        await store.write(StorageKeys.customers, <Object?>[]);

        expect(await backend.create(store).load(), isEmpty);
      });

      test('stored values win over the seed, extra keys are ignored', () async {
        await store.write(StorageKeys.customers, [
          {..._c('3', 'Stored', points: -7).toJson(), 'extra': 1},
        ]);

        expect(await backend.create(store).load(), [
          _c('3', 'Stored', points: -7),
        ]);
      });

      // Current behavior (kept, not fixed): Customer.fromJson uses bare casts,
      // so any bad record makes the whole load() throw a TypeError.
      for (final bad in <String, Object?>{
        'missing field': {'id': '1', 'name': 'A', 'phone': '', 'email': ''},
        'wrong type': {..._c('1', 'A').toJson(), 'points': '5'},
        'double points': {..._c('1', 'A').toJson(), 'points': 250.5},
        'null name': {..._c('1', 'A').toJson(), 'name': null},
        'not a map': 'x',
      }.entries) {
        test('a bad record (${bad.key}) makes load throw TypeError', () async {
          await store.write(StorageKeys.customers, [
            _c('0', 'Good').toJson(),
            bad.value,
          ]);

          await expectLater(
            backend.create(store).load(),
            throwsA(isA<TypeError>()),
          );
        });
      }

      test('a stored null (not a list) makes load throw TypeError', () async {
        await store.write(StorageKeys.customers, null);

        await expectLater(
          backend.create(store).load(),
          throwsA(isA<TypeError>()),
        );
      });

      test('no validation: empty names and negative points are kept', () async {
        final list = [_c('1', '', points: -50)];
        final repo = backend.create(store);
        await repo.load();
        await repo.save(list);

        expect(await backend.create(store).load(), list);
      });
    });
  }

  // The one intended difference (KG-132, DEC-126): the table has a UNIQUE
  // legacy id, so Drift imports a duplicate id as `<id>~dupN`; Mock keeps both.
  test(
    'duplicate ids: Mock keeps both, Drift renames and never drops',
    () async {
      final list = [_c('5', 'A'), _c('5', 'B')];
      for (final (make, expected) in [
        (_mock, ['5', '5']),
        (_drift, ['5', '5~dup2']),
      ]) {
        final backend = make();
        final store = InMemoryLocalStore();
        await store.write(StorageKeys.customers, [
          for (final c in list) c.toJson(),
        ]);

        final loaded = await backend.create(store).load();

        expect(_ids(loaded), expected);
        expect(loaded.map((c) => c.name), ['A', 'B']);
        await backend.dispose?.call();
      }
    },
  );
}
