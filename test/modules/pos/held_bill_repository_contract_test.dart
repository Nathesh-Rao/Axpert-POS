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
import 'package:pos_application/modules/pos/models/held_bill.dart';
import 'package:pos_application/modules/pos/repository/drift_held_bill_repository.dart';
import 'package:pos_application/modules/pos/repository/held_bill_repository.dart';
import 'package:pos_application/modules/pos/repository/mock_held_bill_repository.dart';

import '../../support/held_fixtures.dart';

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

  final HeldBillRepository Function(LocalStore store) create;
  final Future<void> Function()? dispose;
}

_Backend _mock() => _Backend(MockHeldBillRepository.new);

_Backend _drift() {
  final db = AxpertDatabase(NativeDatabase.memory());
  return _Backend(
    (store) => DriftHeldBillRepository(
      provider: _Provider(db),
      store: store,
      diagnostics: StartupDiagnostics(),
      uuid: UuidV4Generator(),
    ),
    db.close,
  );
}

List<String> _refs(List<HeldBill> list) => [for (final b in list) b.ref];

List<Map<String, dynamic>> _json(List<HeldBill> list) => [
  for (final b in list) b.toJson(),
];

void main() {
  setUp(() => MockDelay.provider = () => Duration.zero);

  final backends = <String, _Backend Function()>{
    'Mock': _mock,
    'Drift (in-memory)': _drift,
  };
  for (final entry in backends.entries) {
    final make = entry.value;
    group('HeldBillRepository contract: ${entry.key}', () {
      late _Backend backend;
      late InMemoryLocalStore store;

      setUp(() {
        backend = make();
        store = InMemoryLocalStore();
      });
      tearDown(() async => backend.dispose?.call());

      test('first load is empty (nothing is seeded)', () async {
        expect(await backend.create(store).load(), isEmpty);
      });

      test('save then load on a new instance round-trips in order', () async {
        final list = [
          heldBill('H3', productId: 3),
          heldBill('H1'),
          heldBill('H2', productId: 2, qtyMilli: 1500, note: 'late'),
        ];
        final repo = backend.create(store);
        await repo.load();
        await repo.save(list);

        final loaded = await backend.create(store).load();

        expect(_refs(loaded), ['H3', 'H1', 'H2']);
        expect(_json(loaded), _json(list));
      });

      test(
        'app add appends at the end, remove drops one, clear empties',
        () async {
          final repo = backend.create(store);
          await repo.load();
          var list = [heldBill('A')];
          await repo.save(list);
          list = [...list, heldBill('B', productId: 2)];
          await repo.save(list);
          list = [...list, heldBill('C', productId: 3)];
          await repo.save(list);
          expect(_refs(await backend.create(store).load()), ['A', 'B', 'C']);

          list = [
            for (final b in list)
              if (b.ref != 'B') b,
          ];
          await repo.save(list);
          expect(_refs(await backend.create(store).load()), ['A', 'C']);

          await repo.save(<HeldBill>[]);
          expect(await backend.create(store).load(), isEmpty);
        },
      );

      test('a reordered or shortened list reloads exactly as saved', () async {
        final repo = backend.create(store);
        await repo.load();
        await repo.save([heldBill('A'), heldBill('B'), heldBill('C')]);
        await repo.save([heldBill('C'), heldBill('A')]);

        expect(_refs(await backend.create(store).load()), ['C', 'A']);
      });

      test('a ref used again after removal comes back as a new bill', () async {
        final repo = backend.create(store);
        await repo.load();
        await repo.save([heldBill('A')]);
        await repo.save(<HeldBill>[]);
        await repo.save([heldBill('A', productId: 4)]);

        final loaded = await backend.create(store).load();

        expect(_refs(loaded), ['A']);
        expect(loaded.single.cart.lines.single.product.id, 4);
      });

      // KG-125: refs come from the clock and can collide. Both backends keep
      // every bill, in order, with the ref unchanged.
      test('duplicate refs: all kept in order, ref unchanged', () async {
        final list = [
          heldBill('H7', productId: 1),
          heldBill('H7', productId: 2),
          heldBill('H8'),
        ];
        await store.write(StorageKeys.held, _json(list));

        final loaded = await backend.create(store).load();

        expect(_refs(loaded), ['H7', 'H7', 'H8']);
        expect(_json(loaded), _json(list));

        final repo = backend.create(store);
        await repo.load();
        await repo.save([...list, heldBill('H7', productId: 3)]);
        final again = await backend.create(store).load();
        expect(_refs(again), ['H7', 'H7', 'H8', 'H7']);
        expect(again.map((b) => b.cart.lines.first.product.id), [1, 2, 1, 3]);
      });

      test('a stored [] stays empty', () async {
        await store.write(StorageKeys.held, <Object?>[]);
        expect(await backend.create(store).load(), isEmpty);
      });

      test('a stored value that is not a list loads as empty', () async {
        for (final value in <Object?>[
          null,
          'x',
          5,
          {'a': 1},
        ]) {
          await store.write(StorageKeys.held, value);
          expect(await backend.create(store).load(), isEmpty);
        }
      });

      test('stored values win, unknown extra keys are ignored', () async {
        await store.write(StorageKeys.held, [
          {...heldBill('H1').toJson(), 'extra': 1},
        ]);

        final loaded = await backend.create(store).load();

        expect(_json(loaded), _json([heldBill('H1')]));
      });

      final good = heldBill('G').toJson();
      for (final bad in <String, Object?>{
        'missing ref': {'time': 't', 'cart': good['cart']},
        'null ref': {...good, 'ref': null},
        'wrong-type time': {...good, 'time': 5},
        'missing cart': {'ref': 'H', 'time': 't'},
        'cart not a map': {...good, 'cart': 'x'},
        'cart without lines': {
          ...good,
          'cart': {...(good['cart'] as Map<String, dynamic>)}..remove('lines'),
        },
        'bad line': {
          ...good,
          'cart': {
            ...(good['cart'] as Map<String, dynamic>),
            'lines': [
              {'qty': 'x'},
            ],
          },
        },
        'not a map': 'x',
      }.entries) {
        test('a bad record (${bad.key}) makes load throw TypeError', () async {
          await store.write(StorageKeys.held, [good, bad.value]);

          await expectLater(
            backend.create(store).load(),
            throwsA(isA<TypeError>()),
          );
        });
      }

      test('no validation: empty ref and odd time text are kept', () async {
        final list = [heldBill('', time: 'not a date')];
        final repo = backend.create(store);
        await repo.load();
        await repo.save(list);

        final loaded = await backend.create(store).load();

        expect(loaded.single.ref, '');
        expect(loaded.single.time, 'not a date');
      });

      test(
        'an empty cart and a customer/discount snapshot round-trip',
        () async {
          final list = [
            HeldBill(
              ref: 'E',
              time: 't',
              cart: heldBill(
                'x',
                note: 'n',
              ).cart.copyWith(customer: '2', points: 7, reason: 'why'),
            ),
            HeldBill(
              ref: 'F',
              time: 't',
              cart: heldBill('x').cart.copyWith(lines: []),
            ),
          ];
          final repo = backend.create(store);
          await repo.load();
          await repo.save(list);

          expect(_json(await backend.create(store).load()), _json(list));
        },
      );
    });
  }
}
