import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/pricing_models.dart';
import 'package:pos_application/core/services/pricing/pricing_service.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/pricing/rational.dart';
import 'package:pos_application/core/services/pricing/tax_config.dart';
import 'package:pos_application/features/offers/domain/entities/offer.dart';
import 'package:pos_application/features/offers/domain/services/offer_engine.dart';
import 'package:pos_application/features/products/domain/entities/product.dart';

const _inr = CurrencyRegistry.inr;
final _now = DateTime(2026, 10, 12, 12);
const _engine = OfferEngine();

Money _m(int minor) => Money(minor, _inr);

Product _product(int id, {int price = 10000, int stock = 50}) => Product(
  id: id,
  name: 'P$id',
  code: 'C$id',
  barcode: 'B$id',
  price: _m(price),
  category: 'c',
  sub: 's',
  stock: stock,
  gst: const Bp(1800),
  image: -1,
  favourite: false,
);

Offer _offer(Map<String, dynamic> o, int index) {
  final kind = OfferKind.parse(
    o['kind'] == 'gift' ? 'gift_tier' : o['kind'] as String,
  );
  return Offer(
    id: 'o$index',
    kind: kind,
    name: '${o['kind']} $index',
    productId: o['p'] as int?,
    percent: o['bp'] == null ? null : Bp(o['bp'] as int),
    fixedOff: o['fixed'] == null ? null : _m(o['fixed'] as int),
    priority: (o['priority'] as int?) ?? 0,
  );
}

/// Calculates a cart through the engine and the pricing service.
(CartTotals, OfferResolution) _run(
  List<OfferLine> lines,
  List<Offer> offers,
  List<int> gst, {
  TaxMode mode = TaxMode.exclusive,
  DateTime? now,
}) {
  final res = _engine.resolve(
    lines: lines,
    offers: offers,
    now: now ?? _now,
    currency: _inr,
  );
  final totals = PricingService(config: TaxConfig.india.copyWith(mode: mode))
      .calculate(
        CartInput(
          lines: [
            for (var i = 0; i < lines.length; i++)
              LineInput(
                qty: lines[i].qty,
                price: lines[i].price,
                taxRate: Bp(gst[i]),
                discount: res.lines[i]?.discount ?? lines[i].manualDiscount,
                unitOff: res.lines[i]?.unitOff,
              ),
          ],
        ),
      );
  return (totals, res);
}

void main() {
  final doc =
      jsonDecode(File('test/fixtures/offers_golden.json').readAsStringSync())
          as Map<String, dynamic>;
  final cases = (doc['cases'] as List).cast<Map<String, dynamic>>();

  group('offer vectors (engine + pricing)', () {
    for (final c in cases) {
      test('${c['id']} ${c['name']}', () {
        final lines = <OfferLine>[];
        final gst = <int>[];
        for (final l in (c['lines'] as List).cast<Map<String, dynamic>>()) {
          lines.add(
            OfferLine(
              productId: l['p'] as int,
              qty: Qty.parse(l['qty'] as String),
              price: _m(l['price'] as int),
              manualDiscount: Bp((l['manual'] as int?) ?? 0),
            ),
          );
          gst.add(l['gst'] as int);
        }
        final offers = <Offer>[
          for (final e
              in (c['offers'] as List).cast<Map<String, dynamic>>().indexed)
            _offer(e.$2, e.$1),
        ];
        final (t, res) = _run(
          lines,
          offers,
          gst,
          mode: c['mode'] == 'inclusive'
              ? TaxMode.inclusive
              : TaxMode.exclusive,
        );
        final exp = (c['expected'] as Map).cast<String, dynamic>();
        expect(t.value.minor, exp['value'], reason: 'value');
        expect(t.discount.minor, exp['discount'], reason: 'discount');
        expect(t.tax.minor, exp['tax'], reason: 'tax');
        expect(t.total.minor, exp['total'], reason: 'total');
        expect(res.saving.minor, exp['saving'], reason: 'saving');
      });
    }

    test('promo math re-derived independently (exact fractions)', () {
      // net = qty/1000 * price / 2, tax = net * 18/100, rounded once.
      for (final milli in [1000, 2000, 3000, 1500, 333, 7250]) {
        for (final price in [10000, 9999, 12345]) {
          final lines = [
            OfferLine(
              productId: 1,
              qty: Qty(milli),
              price: _m(price),
              manualDiscount: Bp.zero,
            ),
          ];
          final (t, _) = _run(
            lines,
            [
              const Offer(
                id: 'x',
                kind: OfferKind.promotion,
                name: 'x',
                productId: 1,
                percent: Bp(5000),
              ),
            ],
            [1800],
          );
          final net = Rational(BigInt.from(milli * price), BigInt.from(2000));
          final tax = net * Rational(BigInt.from(18), BigInt.from(100));
          expect(t.tax.minor, tax.roundHalfUp().toInt());
          expect(t.total.minor, (net + tax).roundHalfUp().toInt());
        }
      }
    });
  });

  group('offer-free carts are unchanged', () {
    test('no offers and unitOff null give identical totals', () {
      final lines = [
        OfferLine(
          productId: 1,
          qty: const Qty(2500),
          price: _m(9999),
          manualDiscount: const Bp(750),
        ),
      ];
      final (withEngine, res) = _run(lines, const [], [1200]);
      final plain = const PricingService().calculate(
        CartInput(
          lines: [
            LineInput(
              qty: const Qty(2500),
              price: _m(9999),
              taxRate: const Bp(1200),
              discount: const Bp(750),
            ),
          ],
        ),
      );
      expect(res.lines.single, isNull);
      expect(withEngine.total, plain.total);
      expect(withEngine.tax, plain.tax);
      expect(withEngine.discount, plain.discount);
      expect(withEngine.value, plain.value);
    });
  });

  group('rules', () {
    OfferLine line(int id, {int price = 10000, int qtyUnits = 1}) => OfferLine(
      productId: id,
      qty: Qty.units(qtyUnits),
      price: _m(price),
      manualDiscount: Bp.zero,
    );

    test('expired, future and other-store offers are ignored', () {
      final offers = [
        Offer(
          id: 'a',
          kind: OfferKind.promotion,
          name: 'old',
          productId: 1,
          percent: const Bp(5000),
          endsAt: _now.subtract(const Duration(days: 1)),
        ),
        Offer(
          id: 'b',
          kind: OfferKind.promotion,
          name: 'soon',
          productId: 1,
          percent: const Bp(5000),
          startsAt: _now.add(const Duration(days: 1)),
        ),
        const Offer(
          id: 'c',
          kind: OfferKind.promotion,
          name: 'other',
          storeId: 'store-2',
          productId: 1,
          percent: Bp(5000),
        ),
      ];
      final res = _engine.resolve(
        lines: [line(1)],
        offers: offers,
        now: _now,
        currency: _inr,
        storeId: 'store-1',
      );
      expect(res.lines.single, isNull);
      expect(res.saving.minor, 0);
    });

    test('higher priority discount wins, then larger percent', () {
      const a = Offer(
        id: 'a',
        kind: OfferKind.discount,
        name: 'a',
        productId: 1,
        percent: Bp(1000),
        priority: 2,
      );
      const b = Offer(
        id: 'b',
        kind: OfferKind.discount,
        name: 'b',
        productId: 1,
        percent: Bp(3000),
      );
      final res = _engine.resolve(
        lines: [line(1)],
        offers: [a, b],
        now: _now,
        currency: _inr,
      );
      expect(res.lines.single!.offerId, 'a');
    });

    test('fixed offer in another currency is ignored', () {
      const offer = Offer(
        id: 'a',
        kind: OfferKind.discount,
        name: 'usd',
        productId: 1,
        fixedOff: Money(100, CurrencyRegistry.usd),
      );
      final res = _engine.resolve(
        lines: [line(1)],
        offers: [offer],
        now: _now,
        currency: _inr,
      );
      expect(res.lines.single, isNull);
    });

    group('free item tier at 500.00', () {
      final gift = _product(99, price: 4000);
      final tier = Offer(
        id: 't',
        kind: OfferKind.giftTier,
        name: 'Spend 500',
        minCart: _m(50000),
        gift: gift,
      );
      final promo = const Offer(
        id: 'p',
        kind: OfferKind.promotion,
        name: 'bogo',
        productId: 2,
        percent: Bp(5000),
      );

      GiftRow row(List<OfferLine> lines, [List<Offer>? extra]) => _engine
          .resolve(
            lines: lines,
            offers: [tier, ...?extra],
            now: _now,
            currency: _inr,
          )
          .gifts
          .single;

      test('499.99 locked (1 to go), 500.00 unlocked, back down relocks', () {
        final low = row([line(1, price: 49999)]);
        expect(low.unlocked, isFalse);
        expect(low.remaining.minor, 1);
        final at = row([line(1, price: 50000)]);
        expect(at.unlocked, isTrue);
        expect(at.remaining.minor, 0);
        final down = row([line(1, price: 25000, qtyUnits: 1)]);
        expect(down.unlocked, isFalse);
        expect(down.remaining.minor, 25000);
        final up = row([line(1, price: 25000, qtyUnits: 2)]);
        expect(up.unlocked, isTrue);
      });

      test('uses the value after promotions', () {
        // 999.98 of promo goods is worth 499.99 after half price: locked.
        expect(row([line(2, price: 99998)], [promo]).unlocked, isFalse);
        expect(row([line(2, price: 100000)], [promo]).unlocked, isTrue);
      });

      test('gift without stock is not offered', () {
        final empty = Offer(
          id: 'e',
          kind: OfferKind.giftTier,
          name: 'x',
          minCart: _m(100),
          gift: _product(98, stock: 0),
        );
        final res = _engine.resolve(
          lines: [line(1)],
          offers: [empty],
          now: _now,
          currency: _inr,
        );
        expect(res.gifts, isEmpty);
      });

      test('gift lines do not change totals (price 0, no gift in pricing)', () {
        final (t1, _) = _run([line(1, price: 60000)], [tier], [1800]);
        final (t2, _) = _run([line(1, price: 60000)], const [], [1800]);
        expect(t1.total, t2.total);
      });
    });
  });
}
