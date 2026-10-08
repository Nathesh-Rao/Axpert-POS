import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/pricing_models.dart';
import 'package:pos_application/core/services/pricing/pricing_service.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/pricing/rational.dart';

import '../../fixtures/pricing_golden_data.g.dart';

const _inr = CurrencyRegistry.inr;

CartInput _cart(Map<String, dynamic> v) {
  final flat = v['discountType'] == 'flat';
  final bd = v['billDiscount'] as String;
  return CartInput(
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
}

void main() {
  final doc = jsonDecode(pricingGoldenJson) as Map<String, dynamic>;
  final vectors = (doc['vectors'] as List).cast<Map<String, dynamic>>();
  const service = PricingService();

  test('fixture holds about 300 vectors', () {
    expect(vectors.length, greaterThanOrEqualTo(290));
    expect(doc['count'], vectors.length);
  });

  test('every field equals the real React calculate()', () {
    final ties = <String>[];
    final failures = <String>[];
    for (final v in vectors) {
      final id = v['id'] as String;
      final exp = (v['expected'] as Map).cast<String, dynamic>();
      final got = service.calculate(_cart(v));
      expect(got.items, exp['items'], reason: id);
      expect(got.qty.milli, exp['qtyMilli'], reason: '$id qty');
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
        // Only a 1-minor-unit miss at a true rational tie is accepted.
        final isTie = exact.isTie && (m.minor - want).abs() == 1;
        (isTie ? ties : failures).add('$id.$name got ${m.minor} want $want');
      });
    }
    if (ties.isNotEmpty) {
      // ignore: avoid_print
      print('TIES (${ties.length}): ${ties.join('; ')}');
    }
    expect(failures, isEmpty);
  });
}
