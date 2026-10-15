import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/inventory/inventory_service.dart';

void main() {
  const service = InventoryService();
  var n = 0;
  String id() => 'tx-${++n}';

  StockPlan plan(
    List<StockMovement> movements, {
    Map<String, int> balances = const {},
    Map<String, int> stockUnits = const {},
    bool allowNegative = false,
  }) => service.plan(
    storeId: 's1',
    userId: 'u1',
    now: 1000,
    movements: movements,
    balances: balances,
    stockUnits: stockUnits,
    allowNegative: allowNegative,
    newId: id,
  );

  StockMovement sale(String p, int milli, {String ref = 'sale-1'}) =>
      StockMovement(
        productId: p,
        deltaMilli: -milli,
        reason: StockReason.sale,
        refType: 'sale',
        refId: ref,
      );

  setUp(() => n = 0);

  test('a sale lowers the balance and writes one row', () {
    final p = plan(
      [sale('a', 2000)],
      balances: {'a': 5000},
      stockUnits: {'a': 5},
    );
    expect(p.isBlocked, isFalse);
    expect(p.balances, {'a': 3000});
    expect(p.transactions, hasLength(1));
    final t = p.transactions.single;
    expect(
      (t.deltaMilli, t.reason, t.refType, t.refId, t.storeId, t.userId),
      (-2000, StockReason.sale, 'sale', 'sale-1', 's1', 'u1'),
    );
    expect(t.createdAt, 1000);
  });

  test('fractional quantities are exact in milli-units', () {
    final p = plan(
      [sale('a', 1250)],
      balances: {'a': 5000},
      stockUnits: {'a': 5},
    );
    expect(p.balances['a'], 3750);
  });

  test('lines of the same product merge into one row', () {
    final p = plan(
      [sale('a', 1000), sale('a', 2500), sale('b', 1000)],
      balances: {'a': 9000, 'b': 1000},
      stockUnits: {'a': 9, 'b': 1},
    );
    expect(p.transactions, hasLength(2));
    expect(p.balances, {'a': 5500, 'b': 0});
    expect(
      p.transactions.firstWhere((t) => t.productId == 'a').deltaMilli,
      -3500,
    );
  });

  test('zero stock: selling is blocked, not applied', () {
    final p = plan([sale('a', 1000)], balances: {'a': 0}, stockUnits: {'a': 0});
    expect(p.isBlocked, isTrue);
    expect(p.blocked.single.availableMilli, 0);
    expect(p.blocked.single.requestedMilli, 1000);
    expect(p.negative, isEmpty);
  });

  test('selling exactly the balance is allowed', () {
    final p = plan(
      [sale('a', 5000)],
      balances: {'a': 5000},
      stockUnits: {'a': 5},
    );
    expect(p.isBlocked, isFalse);
    expect(p.balances['a'], 0);
  });

  test('negative stock allowed: applied, reported, noted', () {
    final p = plan(
      [sale('a', 3000)],
      balances: {'a': 1000},
      stockUnits: {'a': 1},
      allowNegative: true,
    );
    expect(p.isBlocked, isFalse);
    expect(p.balances['a'], -2000);
    expect(p.negative.single.productId, 'a');
    expect(p.transactions.single.note, contains('negative stock'));
  });

  test('a return restores stock and never blocks', () {
    final p = plan(
      [
        const StockMovement(
          productId: 'a',
          deltaMilli: 1500,
          reason: StockReason.returned,
          refType: 'sale',
          refId: 'sale-1',
        ),
      ],
      balances: {'a': 0},
      stockUnits: {'a': 0},
    );
    expect(p.isBlocked, isFalse);
    expect(p.balances['a'], 1500);
    expect(p.transactions.single.reason, StockReason.returned);
  });

  test('no balance row yet: an opening row is created from the cache', () {
    final p = plan([sale('a', 2000)], stockUnits: {'a': 7});
    expect(p.transactions.map((t) => t.reason), [
      StockReason.opening,
      StockReason.sale,
    ]);
    expect(p.transactions.first.deltaMilli, 7000);
    expect(p.balances['a'], 5000);
  });

  test('the cache was edited: an adjustment row moves the balance to it', () {
    final p = plan(
      [sale('a', 1000)],
      balances: {'a': 5000},
      stockUnits: {'a': 100},
    );
    expect(p.transactions.first.reason, StockReason.adjustment);
    expect(p.transactions.first.deltaMilli, 95000);
    expect(p.balances['a'], 99000);
  });

  test('a cache reduced by rounded-up units is in sync (no adjustment)', () {
    // Balance 4.250 after selling 0.75 of 5; the cache holds 4 (5 - ceil).
    final p = plan(
      [sale('a', 250)],
      balances: {'a': 4250},
      stockUnits: {'a': 4},
    );
    expect(p.transactions.map((t) => t.reason), [StockReason.sale]);
    expect(p.balances['a'], 4000);
  });

  test('every reason round-trips through its code', () {
    for (final r in StockReason.values) {
      expect(StockReason.fromCode(r.code), r);
    }
    expect(StockReason.returned.code, 'return');
  });
}
