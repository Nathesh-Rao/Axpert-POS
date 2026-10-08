// S6 formula verification: refund amount, forex card and points clamp against
// vectors generated from React (tool/golden/gen_s6_vectors.mjs). A 1-minor-unit
// miss is accepted only at a true rational tie and is printed for the
// known-gaps list (like KG-079); anything else fails.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/pricing_helpers.dart';
import 'package:pos_application/core/services/pricing/pricing_models.dart';
import 'package:pos_application/core/services/pricing/pricing_service.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/pricing/rational.dart';

import '../../fixtures/s6_golden_data.g.dart';

const _inr = CurrencyRegistry.inr;

void main() {
  final doc = jsonDecode(s6GoldenJson) as Map<String, dynamic>;
  List<Map<String, dynamic>> list(String key) =>
      (doc[key] as List).cast<Map<String, dynamic>>();

  test('fixture sizes', () {
    expect(list('refunds').length, greaterThanOrEqualTo(100));
    expect(list('forex').length, greaterThanOrEqualTo(100));
    expect(list('points').length, greaterThanOrEqualTo(60));
  });

  test('refund amount equals the App.tsx expression', () {
    final ties = <String>[];
    final failures = <String>[];
    for (final v in list('refunds')) {
      final id = v['id'] as String;
      final lines = (v['lines'] as List).cast<Map<String, dynamic>>();
      final refundLines = <RefundLine>[
        for (final r in (v['returns'] as List).cast<Map<String, dynamic>>())
          RefundLine(
            soldQty: Qty.parse(lines[r['line'] as int]['qty'] as String),
            price: Money.parse(
              lines[r['line'] as int]['price'] as String,
              _inr,
            ),
            returnQty: Qty.parse(r['qty'] as String),
          ),
      ];
      final total = Money.parse(v['saleTotal'] as String, _inr);
      final value = Money.parse(v['saleValue'] as String, _inr);
      final exact = PricingHelpers.refundExact(
        saleTotal: total,
        saleValue: value,
        lines: refundLines,
      );
      final got = PricingHelpers.refund(
        saleTotal: total,
        saleValue: value,
        lines: refundLines,
      );
      final want = Money.parse(
        (v['expected'] as Map)['amount'] as String,
        _inr,
      );
      if (got == want) continue;
      final isTie = exact.isTie && (got.minor - want.minor).abs() == 1;
      (isTie ? ties : failures).add(
        '$id got ${got.minor} want ${want.minor} (${v['name']})',
      );
    }
    if (ties.isNotEmpty) {
      // ignore: avoid_print
      print('REFUND TIES (${ties.length}): ${ties.join('; ')}');
    }
    expect(failures, isEmpty);
  });

  test('forex card equals total / rate toFixed(2)', () {
    final ties = <String>[];
    final failures = <String>[];
    for (final v in list('forex')) {
      final id = v['id'] as String;
      final total = Money.parse(v['total'] as String, _inr);
      final rate = Rational(
        BigInt.from((double.parse(v['rate'] as String) * 1000).round()),
      );
      final rateMilli = rate.numerator.toInt();
      final exact = PricingHelpers.forexExactHundredths(
        total: total,
        rateMilli: rateMilli,
      );
      final got = PricingHelpers.forexConvertHundredths(
        total: total,
        rateMilli: rateMilli,
      );
      final wantText = v['expected'] as String;
      final want = int.parse(wantText.replaceAll('.', ''));
      if (got == want) continue;
      final isTie = exact.isTie && (got - want).abs() == 1;
      (isTie ? ties : failures).add(
        '$id ${v['total']}/${v['rate']} got $got want $want',
      );
    }
    if (ties.isNotEmpty) {
      // ignore: avoid_print
      print('FOREX TIES (${ties.length}): ${ties.join('; ')}');
    }
    expect(failures, isEmpty);
  });

  test('points clamp equals the real React calculate()', () {
    const service = PricingService();
    final ties = <String>[];
    final failures = <String>[];
    for (final v in list('points')) {
      final id = v['id'] as String;
      final flat = v['discountType'] == 'flat';
      final bd = v['billDiscount'] as String;
      final cart = CartInput(
        lines: [
          for (final l in (v['lines'] as List).cast<Map<String, dynamic>>())
            LineInput(
              qty: Qty.parse(l['qty'] as String),
              price: Money.parse(l['price'] as String, _inr),
              discount: Bp.parsePercent(l['discount'] as String),
              taxRate: Bp.parsePercent(l['gst'] as String),
            ),
        ],
        billDiscount: flat
            ? BillDiscount.flat(Money.parse(bd, _inr))
            : BillDiscount.percent(Bp.parsePercent(bd)),
        pointsToRedeem: int.parse(v['points'] as String),
        availablePoints: int.parse(v['available'] as String),
      );
      final got = service.calculate(cart);
      final exp = (v['expected'] as Map).cast<String, dynamic>();
      final fields = <String, (Money, Rational)>{
        'value': (got.value, got.exact.value),
        'subtotal': (got.subtotal, got.exact.subtotal),
        'discount': (got.discount, got.exact.discount),
        'tax': (got.tax, got.exact.tax),
        'points': (got.points, got.exact.points),
        'total': (got.total, got.exact.total),
      };
      fields.forEach((name, pair) {
        final want = Money.parse(exp[name] as String, _inr).minor;
        final (m, exact) = pair;
        if (m.minor == want) return;
        final isTie = exact.isTie && (m.minor - want).abs() == 1;
        (isTie ? ties : failures).add('$id.$name got ${m.minor} want $want');
      });
    }
    if (ties.isNotEmpty) {
      // ignore: avoid_print
      print('POINTS TIES (${ties.length}): ${ties.join('; ')}');
    }
    expect(failures, isEmpty);
  });
}
