import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/pricing_helpers.dart';
import 'package:pos_application/core/services/pricing/pricing_models.dart';
import 'package:pos_application/core/services/pricing/pricing_service.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/pricing/rational.dart';
import 'package:pos_application/core/services/pricing/rounding_strategy.dart';
import 'package:pos_application/core/services/pricing/tax_config.dart';

const _inr = CurrencyRegistry.inr;
final _incl = TaxConfig.india.copyWith(mode: TaxMode.inclusive);

Money _m(String s) => Money.parse(s, _inr);

LineInput _line(String qty, String price, int gstPct, [String disc = '0']) =>
    LineInput(
      qty: Qty.parse(qty),
      price: _m(price),
      discount: Bp.parsePercent(disc),
      taxRate: Bp(gstPct * 100),
    );

/// Always rounds down: proves the rounding seam is swappable.
class _FloorRounding extends RoundingStrategy {
  const _FloorRounding();

  @override
  int round(Rational minorUnits, RoundingPoint point) =>
      minorUnits.floor().toInt();
}

void main() {
  final inclusive = PricingService(config: _incl);
  const exclusive = PricingService();

  group('inclusive mode', () {
    test('price 118 at 18% contains 18 of tax and totals 118', () {
      final t = inclusive.calculate(CartInput(lines: [_line('1', '118', 18)]));
      expect(t.tax, _m('18'));
      expect(t.total, _m('118'));
      expect(t.value, _m('118'));
      expect(t.discount, _m('0'));
    });

    test('same cart: exclusive adds tax, inclusive does not', () {
      final cart = CartInput(lines: [_line('2', '50', 18)]);
      expect(exclusive.calculate(cart).total, _m('118'));
      expect(inclusive.calculate(cart).total, _m('100'));
      expect(inclusive.calculate(cart).tax.minor, 1525);
    });

    test('bill discount is allocated on gross, tax scales with it', () {
      final t = inclusive.calculate(
        CartInput(
          lines: [_line('1', '112', 12), _line('1', '105', 5)],
          billDiscount: BillDiscount.percent(Bp.parsePercent('10')),
        ),
      );
      expect(t.discount, _m('21.7'));
      expect(t.total, _m('195.3'));
      // 100.8 * 12/112 + 94.5 * 5/105
      expect(t.tax, _m('15.3'));
    });

    test('points are capped at the discounted gross', () {
      final t = inclusive.calculate(
        CartInput(
          lines: [_line('1', '40', 18)],
          pointsToRedeem: 500,
          availablePoints: 1000,
        ),
      );
      expect(t.points, _m('40'));
      expect(t.total, _m('0'));
    });

    test('invariants hold on random carts in both modes', () {
      final rng = Random(7);
      const gst = [0, 5, 12, 18];
      for (var i = 0; i < 300; i++) {
        final lines = [
          for (var j = 0; j < rng.nextInt(7); j++)
            LineInput(
              qty: Qty(1 + rng.nextInt(20000)),
              price: Money(rng.nextInt(60000), _inr),
              discount: Bp(rng.nextBool() ? 0 : rng.nextInt(10001)),
              taxRate: Bp(gst[rng.nextInt(4)] * 100),
            ),
        ];
        final sub = lines.fold<int>(
          0,
          (s, l) => s + l.price.minor * l.qty.milli ~/ 1000,
        );
        final flat = rng.nextBool();
        final cart = CartInput(
          lines: lines,
          billDiscount: flat
              ? BillDiscount.flat(Money(rng.nextInt(sub + 1000), _inr))
              : BillDiscount.percent(Bp(rng.nextInt(12001))),
          pointsToRedeem: rng.nextInt(300),
          availablePoints: rng.nextInt(300),
        );
        for (final service in [inclusive, exclusive]) {
          final e = service.calculateExact(cart);
          final netSum = e.lines.fold(Rational.zero, (s, l) => s + l.net);
          final discounted = e.value - e.discount;
          // value - discount = discounted line total (S - BD), never negative
          expect(discounted.isNegative, isFalse, reason: 'case $i');
          expect(discounted <= netSum, isTrue);
          expect(e.points <= discounted + e.tax, isTrue);
          expect(e.total.isNegative, isFalse);
          if (service == inclusive) {
            expect(e.total, discounted - e.points);
            expect(e.tax <= discounted, isTrue);
          } else {
            expect(e.total, discounted + e.tax - e.points);
          }
        }
        // zero-rate lines carry no tax
        final zero = CartInput(
          lines: List.generate(lines.length, (_) => _line('1', '10', 0)),
        );
        expect(inclusive.calculate(zero).tax.minor, 0);
      }
    });

    test('rejects a line in another currency', () {
      expect(
        () => inclusive.calculate(
          CartInput(
            lines: [
              LineInput(
                qty: Qty.units(1),
                price: const Money(100, CurrencyRegistry.usd),
                taxRate: Bp.zero,
              ),
            ],
          ),
        ),
        throwsA(isA<CurrencyMismatch>()),
      );
    });
  });

  test('rounding seam: a stub strategy changes the result', () {
    final cart = CartInput(lines: [_line('1', '0.33', 18)]);
    final proto = exclusive.calculate(cart);
    final stub = const PricingService(
      rounding: _FloorRounding(),
    ).calculate(cart);
    expect(proto.tax.minor, 6); // 5.94 -> 6
    expect(stub.tax.minor, 5);
  });

  group('helpers', () {
    test('change due: cash only, never negative', () {
      expect(
        PricingHelpers.changeDue(
          total: _m('118'),
          tendered: _m('200'),
          isCash: true,
        ),
        _m('82'),
      );
      expect(
        PricingHelpers.changeDue(
          total: _m('118'),
          tendered: _m('100'),
          isCash: true,
        ),
        _m('0'),
      );
      expect(
        PricingHelpers.changeDue(
          total: _m('118'),
          tendered: _m('200'),
          isCash: false,
        ),
        _m('0'),
      );
    });

    test('refund share is pro rata on the sale total', () {
      final refund = PricingHelpers.refund(
        saleTotal: _m('118'),
        saleValue: _m('100'),
        lines: [
          RefundLine(
            soldQty: Qty.units(2),
            price: _m('50'),
            returnQty: Qty.units(1),
          ),
        ],
      );
      expect(refund, _m('59'));
      expect(
        PricingHelpers.refund(
          saleTotal: _m('0'),
          saleValue: _m('0'),
          lines: const [],
        ),
        _m('0'),
      );
    });

    test('forex convert is total / rate with 2 decimals', () {
      expect(
        PricingHelpers.forexConvertHundredths(
          total: _m('856.1'),
          rateMilli: 8561,
        ),
        10000 ~/ 1, // 856.10 / 8.561 = 100.00 -> 10000 hundredths
      );
      expect(
        PricingHelpers.forexConvertHundredths(
          total: _m('100'),
          rateMilli: 3000,
        ),
        3333,
      );
      expect(
        PricingHelpers.forexConvertHundredths(total: _m('100'), rateMilli: 0),
        0,
      );
    });

    test('bill discount clamps', () {
      expect(
        PricingHelpers.clampPercent(Bp.parsePercent('250')).percent,
        Bp.full,
      );
      expect(PricingHelpers.clampPercent(const Bp(-5)).percent, Bp.zero);
      expect(PricingHelpers.clampFlat(_m('500'), _m('100')).flat, _m('100'));
      expect(PricingHelpers.clampFlat(_m('-3'), _m('100')).flat, _m('0'));
      expect(PricingHelpers.clampFlat(_m('40'), _m('100')).flat, _m('40'));
    });
  });
}
