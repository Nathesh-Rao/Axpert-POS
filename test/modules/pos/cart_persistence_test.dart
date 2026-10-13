// D6.a (characterization, DEC-130): what the cart's persistence does TODAY, locked in before
// any Drift code. The write-behind coalesces: at most one save in flight and one trailing save
// carrying the latest state; saves never overlap; a change that returns the same cart does not
// save; loading does not save; a failing save does not stall later ones.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/modules/customers/controllers/customers_controller.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/customers/repository/customer_repository.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/repository/cart_repository.dart';

import '../../support/product_fixtures.dart';
import '../../support/test_tax.dart';

class _NoCustomers implements CustomerRepository {
  @override
  Future<List<Customer>> load() async => <Customer>[];

  @override
  Future<void> save(List<Customer> customers) async {}
}

/// Records every save; each save waits for the matching gate when [hold] is
/// set, can fail, and counts how many saves ran at the same time.
class _RecordingCarts implements CartRepository {
  final List<Cart> saved = <Cart>[];
  final List<Completer<void>> gates = <Completer<void>>[];
  bool hold = false;
  Object? failNext;
  int running = 0;
  int maxRunning = 0;
  Cart toLoad = Cart.empty;

  @override
  Future<Cart> load() async => toLoad;

  @override
  Future<void> save(Cart cart) async {
    running++;
    if (running > maxRunning) maxRunning = running;
    saved.add(cart);
    try {
      if (hold) {
        final gate = Completer<void>();
        gates.add(gate);
        await gate.future;
      }
      final e = failNext;
      if (e != null) {
        failNext = null;
        throw e;
      }
    } finally {
      running--;
    }
  }
}

Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  late _RecordingCarts repo;
  late CartController cart;

  setUp(() {
    repo = _RecordingCarts();
    cart = CartController(
      repo,
      CustomersController(_NoCustomers()),
      pricing: testIndiaPricing,
    );
  });

  test('one change is one save, carrying that state', () async {
    cart.addItem(prod(1));
    await cart.flush();

    expect(repo.saved, hasLength(1));
    expect(repo.saved.single.lines.single.product.id, 1);
  });

  test('a burst while a save is in flight is exactly two saves', () async {
    repo.hold = true;
    cart.addItem(prod(1));
    await _tick();
    expect(repo.saved, hasLength(1), reason: 'the first save started at once');

    for (var i = 0; i < 20; i++) {
      cart.setQty(1, Qty(1000 + i));
    }
    cart.setPrice(1, const Money(3333, CurrencyRegistry.inr));
    await _tick();
    expect(repo.saved, hasLength(1), reason: 'nothing else starts meanwhile');

    repo.hold = false;
    repo.gates.single.complete();
    await cart.flush();

    expect(repo.saved, hasLength(2));
    expect(repo.saved.first.lines.single.qty, Qty.units(1));
    expect(repo.saved.last.lines.single.qty, const Qty(1019));
    expect(repo.saved.last.lines.single.price.minor, 3333);
    expect(identical(repo.saved.last, cart.cart.value), isTrue);
  });

  test('saves never overlap, even across several bursts', () async {
    repo.hold = true;
    for (var burst = 0; burst < 3; burst++) {
      cart.addItem(prod(burst));
      cart.addItem(prod(burst));
      await _tick();
      while (repo.gates.any((g) => !g.isCompleted)) {
        repo.gates.firstWhere((g) => !g.isCompleted).complete();
        await _tick();
      }
    }
    repo.hold = false;
    await cart.flush();

    expect(repo.maxRunning, 1);
    expect(repo.saved.last.lines, hasLength(3));
  });

  test('flush waits for the pending save and the trailing one', () async {
    repo.hold = true;
    cart.addItem(prod(1));
    cart.addItem(prod(2));
    var done = false;
    final flushed = cart.flush().then((_) => done = true);
    await _tick();
    expect(done, isFalse);

    repo.hold = false;
    repo.gates.single.complete();
    await flushed;

    expect(done, isTrue);
    expect(repo.saved, hasLength(2));
    expect(repo.saved.last.lines, hasLength(2));
  });

  test('a change that returns the same cart saves nothing', () async {
    cart.addItem(prod(1));
    await cart.flush();
    final before = repo.saved.length;

    cart.patch((c) => c);
    cart.setQty(
      99,
      Qty.units(1),
    ); // unknown product: the reducer rebuilds the same lines
    await cart.flush();

    expect(
      repo.saved.length,
      before + 1,
      reason: 'only the rebuilt-list change',
    );
    final count = repo.saved.length;
    cart.patch((c) => c);
    await cart.flush();
    expect(repo.saved.length, count);
  });

  test('loading the draft does not save it back', () async {
    repo.toLoad = Cart.empty.addItem(prod(1));

    await cart.load();
    await cart.flush();

    expect(cart.cart.value.lines, hasLength(1));
    expect(repo.saved, isEmpty);
  });

  test(
    'clear saves the empty cart (an empty cart is written, not removed)',
    () async {
      cart.addItem(prod(1));
      await cart.flush();

      cart.clear();
      await cart.flush();

      expect(repo.saved.last.lines, isEmpty);
      expect(repo.saved.last.toJson()['lines'], isEmpty);
    },
  );

  test(
    'a failing save is an unhandled async error and does not stall later saves',
    () async {
      final errors = <Object>[];
      await runZonedGuarded(() async {
        repo.failNext = StateError('disk full');
        cart.addItem(prod(1));
        await _tick();
        await _tick();

        cart.addItem(prod(2));
        await cart.flush();
      }, (e, _) => errors.add(e));

      expect(errors.single, isA<StateError>());
      expect(repo.saved, hasLength(2));
      expect(
        repo.saved.last.lines,
        hasLength(2),
        reason: 'the next change saved again',
      );
    },
  );
}
