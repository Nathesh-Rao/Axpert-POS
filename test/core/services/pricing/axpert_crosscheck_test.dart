// Stage 3 cross-check (integration, D1): axpert_pos computes cart totals with
// `CartTotalsCalculator` (rules below, re-implemented here with plain ints
// from its source, nothing imported from axpert_pos). Our `PricingService`
// stays the single implementation. This test compares both on the same
// no-discount carts (scale <= 3) and records WHERE they agree and differ.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/pricing_models.dart';
import 'package:pos_application/core/services/pricing/pricing_service.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/pricing/tax_config.dart';

/// axpert `Money.multiplyRatio(.., halfUp)` for non-negative values.
int _ratio(int minor, int numerator, int denominator) {
  final product = minor * numerator;
  final quotient = product ~/ denominator;
  final remainder = product % denominator;
  return remainder == 0
      ? quotient
      : (remainder * 2 >= denominator ? quotient + 1 : quotient);
}

class _Line {
  const _Line(this.price, this.milli, this.bps);
  final int price;
  final int milli;
  final int bps;
}

class _Ref {
  const _Ref(this.subtotal, this.tax, this.total);
  final int subtotal;
  final int tax;
  final int total;
}

/// axpert rules: per-line extension rounded half-up (quantity coefficient and
/// 10^scale, here scale 3), per-line tax rounded half-up, totals are sums of
/// the rounded lines.
_Ref _axpert(List<_Line> lines, {required bool inclusive}) {
  var subtotal = 0, tax = 0;
  for (final l in lines) {
    final extended = _ratio(l.price, l.milli, 1000);
    if (inclusive) {
      final t = _ratio(extended, l.bps, 10000 + l.bps);
      tax += t;
      subtotal += extended - t;
    } else {
      tax += _ratio(extended, l.bps, 10000);
      subtotal += extended;
    }
  }
  return _Ref(subtotal, tax, subtotal + tax);
}

CartTotals _ours(List<_Line> lines, {required bool inclusive}) {
  final config = inclusive
      ? TaxConfig.india.copyWith(mode: TaxMode.inclusive)
      : TaxConfig.india;
  return PricingService(config: config).calculate(
    CartInput(
      lines: <LineInput>[
        for (final l in lines)
          LineInput(
            qty: Qty(l.milli),
            price: Money(l.price, CurrencyRegistry.inr),
            taxRate: Bp(l.bps),
          ),
      ],
    ),
  );
}

List<List<_Line>> _carts() {
  final random = Random(20261012);
  const rates = <int>[0, 500, 1200, 1800];
  const quantities = <int>[1000, 2000, 1500, 250, 333, 1, 3000, 7500];
  return <List<_Line>>[
    for (var i = 0; i < 3000; i++)
      <_Line>[
        for (var k = 0; k < 1 + random.nextInt(4); k++)
          _Line(
            1 + random.nextInt(99999),
            random.nextBool()
                ? quantities[random.nextInt(quantities.length)]
                : 1 + random.nextInt(9999),
            rates[random.nextInt(rates.length)],
          ),
      ],
  ];
}

void main() {
  final carts = _carts();

  test('whole-unit quantities, one line: both rules give the same total', () {
    for (final inclusive in <bool>[false, true]) {
      for (final cart in carts) {
        if (cart.length != 1 || cart.first.milli % 1000 != 0) continue;
        final ref = _axpert(cart, inclusive: inclusive);
        final ours = _ours(cart, inclusive: inclusive);
        expect(ours.total.minor, ref.total, reason: '$cart $inclusive');
      }
    }
  });

  test('records the differences between the two rule sets', () {
    final stats = <String, int>{};
    final examples = <String, String>{};
    void note(String key, List<_Line> cart, Object ours, Object ref) {
      stats[key] = (stats[key] ?? 0) + 1;
      examples.putIfAbsent(
        key,
        () =>
            '${cart.map((l) => '(price ${l.price}, milli ${l.milli}, '
                '${l.bps} bp)').join(', ')} ours $ours axpert $ref',
      );
    }

    for (final inclusive in <bool>[false, true]) {
      final mode = inclusive ? 'inclusive' : 'exclusive';
      for (final cart in carts) {
        final ref = _axpert(cart, inclusive: inclusive);
        final ours = _ours(cart, inclusive: inclusive);
        final shape = cart.length == 1 ? 'single-line' : 'multi-line';
        if (ours.total.minor != ref.total) {
          note('$mode total, $shape', cart, ours.total.minor, ref.total);
        }
        if (ours.tax.minor != ref.tax) {
          note('$mode tax, $shape', cart, ours.tax.minor, ref.tax);
        }
        if (ours.subtotal.minor != ref.subtotal) {
          note(
            '$mode subtotal, $shape',
            cart,
            ours.subtotal.minor,
            ref.subtotal,
          );
        }
      }
    }
    // ignore: avoid_print
    print('cross-check over ${carts.length} carts x 2 modes:');
    for (final key in stats.keys.toList()..sort()) {
      // ignore: avoid_print
      print(
        '  ${stats[key]!.toString().padLeft(5)}  $key  e.g. ${examples[key]}',
      );
    }
    // Characterisation: the rule sets are NOT identical (per-line rounding vs
    // exact value rounded once per cart total). If this ever becomes empty the
    // services were aligned and this test must be revisited (docs/integration).
    expect(stats, isNotEmpty);
  });
}
