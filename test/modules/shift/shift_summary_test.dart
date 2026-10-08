// ShiftSummary: today's takings from the sales ledger, in integer minor units
// (plain Dart; VM).
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/modules/shift/services/shift_summary.dart';

import '../../support/sale_fixtures.dart';

Money _inr(int minor) => Money(minor, CurrencyRegistry.inr);

void main() {
  final now = DateTime(2026, 10, 8, 15, 30);

  test('only the sales of the same local calendar day count', () {
    final summary = ShiftSummary.of(
      <dynamic>[
        testSale(
          number: 'a',
          at: DateTime(2026, 10, 8, 0, 0, 0),
          totalMinor: 100,
        ),
        testSale(
          number: 'b',
          at: DateTime(2026, 10, 8, 23, 59, 59),
          totalMinor: 200,
        ),
        testSale(
          number: 'c',
          at: DateTime(2026, 10, 7, 23, 59, 59),
          totalMinor: 400,
        ),
        testSale(
          number: 'd',
          at: DateTime(2026, 10, 9, 0, 0, 0),
          totalMinor: 800,
        ),
        testSale(number: 'e', at: DateTime(2025, 10, 8, 12), totalMinor: 1600),
      ].cast(),
      now,
    );
    expect(summary.sales.map((s) => s.number), <String>['a', 'b']);
    expect(summary.count, 2);
    expect(summary.total, _inr(300));
    expect(summary.day, DateTime(2026, 10, 8));
  });

  test('the day changes with the clock, not the sales', () {
    final sales = [
      testSale(number: 'a', at: DateTime(2026, 10, 8, 23, 59), totalMinor: 500),
    ];
    expect(ShiftSummary.of(sales, DateTime(2026, 10, 8, 23, 59, 59)).count, 1);
    expect(ShiftSummary.of(sales, DateTime(2026, 10, 9, 0, 0, 0)).count, 0);
  });

  test('no sales: everything is zero and the bars are empty', () {
    final summary = ShiftSummary.of(const [], now);
    expect(summary.total, _inr(0));
    expect(summary.count, 0);
    expect(summary.average, _inr(0));
    for (final mode in ShiftSummary.modes) {
      expect(summary.byMode(mode), _inr(0));
      expect(summary.barBasisPoints(summary.byMode(mode)), 0);
    }
  });

  test('the average is exact and rounds half up to a minor unit', () {
    Money average(List<int> totals) => ShiftSummary.of([
      for (var i = 0; i < totals.length; i++)
        testSale(number: '$i', at: now, totalMinor: totals[i]),
    ], now).average;
    expect(average(<int>[100, 101]), _inr(101)); // 100.5 -> 101
    expect(average(<int>[1000]), _inr(1000));
    expect(average(<int>[400, 300, 300]), _inr(333)); // 333.33
    expect(average(<int>[1000, 500, 500]), _inr(667)); // 666.67
    expect(average(<int>[1, 0]), _inr(1)); // 0.5 -> 1
    expect(average(<int>[1, 0, 0]), _inr(0)); // 0.33 -> 0
  });

  test('totals per mode; an unknown mode only counts in the total', () {
    final summary = ShiftSummary.of([
      testSale(number: '1', at: now, mode: 'Cash', totalMinor: 3000),
      testSale(number: '2', at: now, mode: 'Card', totalMinor: 5000),
      testSale(number: '3', at: now, mode: 'Cash', totalMinor: 1000),
      testSale(number: '4', at: now, mode: 'Credit', totalMinor: 500),
      testSale(number: '5', at: now, mode: 'Unpaid', totalMinor: 500),
    ], now);
    expect(summary.total, _inr(10000));
    expect(summary.byMode('Cash'), _inr(4000));
    expect(summary.byMode('Card'), _inr(5000));
    expect(summary.byMode('Credit'), _inr(500));
    expect(summary.byMode('Unpaid'), _inr(500));
    expect(ShiftSummary.modes, <String>['Cash', 'Card', 'Credit']);
  });

  test('bar widths are integer basis points of the total', () {
    final summary = ShiftSummary.of([
      testSale(number: '1', at: now, mode: 'Cash', totalMinor: 5000),
      testSale(number: '2', at: now, mode: 'Card', totalMinor: 2500),
      testSale(number: '3', at: now, mode: 'Credit', totalMinor: 2500),
    ], now);
    expect(summary.barBasisPoints(summary.byMode('Cash')), 5000);
    expect(summary.barBasisPoints(summary.byMode('Card')), 2500);
    expect(summary.barBasisPoints(summary.total), 10000);
    final thirds = ShiftSummary.of([
      testSale(number: '1', at: now, mode: 'Cash', totalMinor: 100),
      testSale(number: '2', at: now, mode: 'Card', totalMinor: 200),
    ], now);
    expect(thirds.barBasisPoints(thirds.byMode('Cash')), 3333);
    expect(thirds.barBasisPoints(thirds.byMode('Card')), 6667);
  });
}
