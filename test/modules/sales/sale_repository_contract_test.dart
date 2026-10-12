import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/core/services/storage/local_store.dart';
import 'package:pos_application/modules/sales/models/sale.dart';
import 'package:pos_application/modules/sales/repository/drift_sale_repository.dart';
import 'package:pos_application/modules/sales/repository/mock_sale_repository.dart';
import 'package:pos_application/modules/sales/repository/sale_repository.dart';

import '../../support/ledger_fixtures.dart';

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

  final SaleRepository Function(LocalStore store) create;
  final Future<void> Function()? dispose;
}

_Backend _mock() => _Backend(MockSaleRepository.new);

_Backend _drift() {
  final db = AxpertDatabase(NativeDatabase.memory());
  return _Backend(
    (store) => DriftSaleRepository(
      provider: _Provider(db),
      store: store,
      diagnostics: StartupDiagnostics(),
      uuid: UuidV4Generator(),
    ),
    db.close,
  );
}

List<String> _numbers(List<Sale> list) => [for (final s in list) s.number];

List<Map<String, dynamic>> _json(List<Sale> list) => [
  for (final s in list) s.toJson(),
];

const String _id1 = '11111111-1111-4111-8111-111111111111';
const String _id2 = '22222222-2222-4222-8222-222222222222';

void main() {
  setUp(() => MockDelay.provider = () => Duration.zero);

  final backends = <String, _Backend Function()>{
    'Mock': _mock,
    'Drift (in-memory)': _drift,
  };
  for (final entry in backends.entries) {
    final make = entry.value;
    group('SaleRepository contract: ${entry.key}', () {
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
          ledgerSale('AX000001', saleId: _id1),
          ledgerSale('AX000002'),
          ledgerSale(
            'AX000003',
            saleId: _id2,
            mode: 'Credit',
            flatDiscount: true,
            returned: {2: const Qty(1000), 1: const Qty(500)},
          ),
        ];
        final repo = backend.create(store);
        await repo.load();
        await repo.save(list);

        final loaded = await backend.create(store).load();

        expect(_numbers(loaded), ['AX000001', 'AX000002', 'AX000003']);
        expect(_json(loaded), _json(list));
        expect(loaded[1].saleId, isNull, reason: 'legacy sale keeps no id');
        expect(loaded[2].returned.keys.toList(), [2, 1]);
      });

      test('the LocalStore key holds the same JSON as before', () async {
        final list = [
          ledgerSale('AX000001', saleId: _id1),
          ledgerSale('AX000002'),
        ];
        final repo = backend.create(store);
        await repo.load();
        await repo.save(list);

        expect(await store.read(StorageKeys.sales), _json(list));
        final stored = await store.read(StorageKeys.sales) as List<dynamic>;
        expect((stored[1] as Map).containsKey('saleId'), isFalse);
      });

      test('app add appends, a return changes only returned', () async {
        final repo = backend.create(store);
        await repo.load();
        var list = [ledgerSale('AX000001', saleId: _id1)];
        await repo.save(list);
        list = [...list, ledgerSale('AX000002', saleId: _id2)];
        await repo.save(list);
        expect(_numbers(await backend.create(store).load()), [
          'AX000001',
          'AX000002',
        ]);

        list = [
          list[0].copyWith(returned: {1: const Qty(1000)}),
          list[1],
        ];
        await repo.save(list);

        final loaded = await backend.create(store).load();
        expect(_json(loaded), _json(list));
        expect(loaded[0].returned, {1: const Qty(1000)});
      });

      test('a reordered or shortened list reloads exactly as saved', () async {
        final repo = backend.create(store);
        await repo.load();
        final a = ledgerSale('AX000001', saleId: _id1);
        final b = ledgerSale('AX000002', saleId: _id2);
        final c = ledgerSale('AX000003');
        await repo.save([a, b, c]);
        await repo.save([c, a]);

        expect(_numbers(await backend.create(store).load()), [
          'AX000003',
          'AX000001',
        ]);

        await repo.save(<Sale>[]);
        expect(await backend.create(store).load(), isEmpty);
      });

      // KG-008: numbers are display only and can collide. Both backends keep
      // every sale, in order, with the number unchanged.
      test('duplicate numbers: all kept in order, number unchanged', () async {
        final list = [
          ledgerSale('AX000001', customerName: 'A'),
          ledgerSale('AX000001', customerName: 'B', saleId: _id1),
          ledgerSale('AX000002'),
        ];
        await store.write(StorageKeys.sales, _json(list));

        final loaded = await backend.create(store).load();

        expect(_numbers(loaded), ['AX000001', 'AX000001', 'AX000002']);
        expect(_json(loaded), _json(list));

        final repo = backend.create(store);
        await repo.load();
        await repo.save([...list, ledgerSale('AX000001', customerName: 'C')]);
        final again = await backend.create(store).load();
        expect(again.map((s) => s.customer), [
          'A',
          'B',
          'Walk-in Customer',
          'C',
        ]);
      });

      test('a stored [] stays empty', () async {
        await store.write(StorageKeys.sales, <Object?>[]);
        expect(await backend.create(store).load(), isEmpty);
      });

      test('a stored value that is not a list loads as empty', () async {
        for (final value in <Object?>[
          null,
          'x',
          5,
          {'a': 1},
        ]) {
          await store.write(StorageKeys.sales, value);
          expect(await backend.create(store).load(), isEmpty);
        }
      });

      test('stored values win, unknown extra keys are ignored', () async {
        await store.write(StorageKeys.sales, [
          {...ledgerSale('AX000001', saleId: _id1).toJson(), 'extra': 1},
        ]);

        final loaded = await backend.create(store).load();

        expect(_json(loaded), _json([ledgerSale('AX000001', saleId: _id1)]));
      });

      final good = ledgerSale('AXG', saleId: _id1).toJson();
      for (final bad in <String, Object?>{
        'missing number': {...good}..remove('number'),
        'null number': {...good, 'number': null},
        'wrong-type date': {...good, 'date': 5},
        'missing cart': {...good}..remove('cart'),
        'missing totals': {...good}..remove('totals'),
        'bad returned': {...good, 'returned': 'x'},
        'bad saleId': {...good, 'saleId': 5},
        'not a map': 'x',
      }.entries) {
        test('a bad record (${bad.key}) makes load throw TypeError', () async {
          await store.write(StorageKeys.sales, [good, bad.value]);

          await expectLater(
            backend.create(store).load(),
            throwsA(isA<TypeError>()),
          );
        });
      }

      test('no validation: empty number and odd date text are kept', () async {
        final list = [
          ledgerSale('', saleId: _id1, date: 'not a date', customerName: ''),
        ];
        final repo = backend.create(store);
        await repo.load();
        await repo.save(list);

        final loaded = await backend.create(store).load();

        expect(loaded.single.number, '');
        expect(loaded.single.date, 'not a date');
        expect(_json(loaded), _json(list));
      });

      test('an empty cart and negative or zero amounts round-trip', () async {
        final base = ledgerSale('AX000001', saleId: _id1, productIds: []);
        final list = [base];
        final repo = backend.create(store);
        await repo.load();
        await repo.save(list);

        expect(_json(await backend.create(store).load()), _json(list));
      });
    });
  }
}
