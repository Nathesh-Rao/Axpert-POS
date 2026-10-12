// CartRepository contract (D6.a for the Mock; D6.d adds Drift): the stored cart is read back
// as saved, and ANY read problem resets silently to the empty cart (no throw, no UI).
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/pricing_models.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/core/services/storage/local_store.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/repository/cart_repository.dart';
import 'package:pos_application/modules/pos/repository/mock_cart_repository.dart';

import '../../support/product_fixtures.dart';

/// One backend under test: [create] builds a repository over the shared
/// [store] (a new call is a "restart" on the same persisted data).
class _Backend {
  _Backend(this.create, [this.dispose]);

  final CartRepository Function(LocalStore store) create;
  final Future<void> Function()? dispose;
}

_Backend _mock() => _Backend(MockCartRepository.new, () async {});

Cart _full() => Cart.empty
    .addItem(prod(1))
    .addItem(prod(2))
    .setQty(2, const Qty(2500))
    .copyWith(
      customer: '2',
      points: 7,
      reason: 'why',
      note: 'n',
      billDiscount: const BillDiscount.percent(Bp(250)),
    );

void main() {
  setUp(() => MockDelay.provider = () => Duration.zero);

  final backends = <String, _Backend Function()>{'Mock': _mock};
  for (final entry in backends.entries) {
    final make = entry.value;
    group('CartRepository contract: ${entry.key}', () {
      late _Backend backend;
      late InMemoryLocalStore store;

      setUp(() {
        backend = make();
        store = InMemoryLocalStore();
      });
      tearDown(() async => backend.dispose?.call());

      test('first load is the empty cart (nothing is seeded)', () async {
        final cart = await backend.create(store).load();

        expect(cart.lines, isEmpty);
        expect(cart.toJson(), Cart.empty.toJson());
      });

      test('save then load on a new instance round-trips everything', () async {
        final repo = backend.create(store);
        await repo.load();
        await repo.save(_full());

        final loaded = await backend.create(store).load();

        expect(loaded.toJson(), _full().toJson());
      });

      test(
        'the latest save wins, an empty cart is stored as the empty cart',
        () async {
          final repo = backend.create(store);
          await repo.load();
          await repo.save(_full());
          await repo.save(Cart.empty);

          final loaded = await backend.create(store).load();

          expect(loaded.lines, isEmpty);
          expect(loaded.toJson(), Cart.empty.toJson());
        },
      );

      test('the LocalStore key holds the same JSON as before', () async {
        final repo = backend.create(store);
        await repo.load();
        await repo.save(_full());

        expect(await store.read(StorageKeys.cart), _full().toJson());
      });

      // The silent reset: whatever is stored, load never throws.
      final good = _full().toJson();
      for (final bad in <String, Object?>{
        'null (missing)': null,
        'a string': 'x',
        'a number': 5,
        'a list': [good],
        'lines is not a list': {...good, 'lines': 5},
        'lines missing': {...good}..remove('lines'),
        'a bad line': {
          ...good,
          'lines': [
            {'product': 'x'},
          ],
        },
        'customer missing': {...good}..remove('customer'),
        'wrong-type points': {...good, 'points': 'x'},
        'wrong-type note': {...good, 'note': 7},
        'an empty map': <String, dynamic>{},
      }.entries) {
        test(
          'a stored value that is ${bad.key} resets silently to empty',
          () async {
            if (bad.value != null) {
              await store.write(StorageKeys.cart, bad.value);
            }

            final loaded = await backend.create(store).load();

            expect(loaded.lines, isEmpty);
            expect(loaded.toJson(), Cart.empty.toJson());
          },
        );
      }

      test('unknown extra keys are ignored', () async {
        await store.write(StorageKeys.cart, {
          ...(_full().toJson()),
          'extra': 1,
        });

        final loaded = await backend.create(store).load();

        expect(loaded.toJson(), _full().toJson());
      });

      test('an unreadable cart is overwritten by the next save', () async {
        await store.write(StorageKeys.cart, 'garbage');
        final repo = backend.create(store);
        expect((await repo.load()).lines, isEmpty);

        await repo.save(_full());

        expect((await backend.create(store).load()).toJson(), _full().toJson());
      });

      test('no validation: stock is not checked, odd text is kept', () async {
        final odd = _full().copyWith(
          note: 'é "quoted" \n new line',
          reason: '',
        );
        final repo = backend.create(store);
        await repo.load();
        await repo.save(odd);

        expect((await backend.create(store).load()).toJson(), odd.toJson());
      });
    });
  }
}
