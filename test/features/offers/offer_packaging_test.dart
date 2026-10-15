// DEC-151: offers on packaging lines. Percent and BOGO act on the line
// (a percent of any packaging); a fixed amount is per BASE unit and scales
// by the packaging factor; free-item tiers compare the cart value.
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/features/offers/domain/entities/offer.dart';
import 'package:pos_application/features/offers/domain/services/offer_engine.dart';
import 'package:pos_application/features/products/domain/entities/product.dart';

const _inr = CurrencyRegistry.inr;
final _now = DateTime(2026, 10, 12, 12);
const _engine = OfferEngine();

OfferLine _line({
  required int qtyMilli,
  required int price,
  int factor = 1000,
}) => OfferLine(
  productId: 1,
  qty: Qty(qtyMilli),
  price: Money(price, _inr),
  manualDiscount: Bp.zero,
  packageFactorMilli: factor,
);

AppliedOffer? _apply(Offer offer, OfferLine line) => _engine
    .resolve(lines: [line], offers: [offer], now: _now, currency: _inr)
    .lines
    .single;

void main() {
  const fixed = Offer(
    id: 'f',
    kind: OfferKind.discount,
    name: 'Rs 0.50 off',
    productId: 1,
    fixedOff: Money(50, _inr),
  );
  const percent = Offer(
    id: 'p',
    kind: OfferKind.discount,
    name: '10%',
    productId: 1,
    percent: Bp(1000),
  );
  const bogo = Offer(
    id: 'b',
    kind: OfferKind.promotion,
    name: 'BOGO',
    productId: 1,
    percent: Bp(5000),
  );

  group('fixed amount is per base unit', () {
    test('a base-unit line is unchanged', () {
      final a = _apply(fixed, _line(qtyMilli: 3000, price: 1000))!;
      expect(a.unitOff!.minor, 50);
      expect(a.saving.minor, 150); // 3 x 0.50
    });

    test('a carton of 24 takes 24 x the per-unit reduction', () {
      // Carton price 240.00 (24 x 10.00); 2 cartons; 0.50 x 24 = 12.00 each.
      final a = _apply(
        fixed,
        _line(qtyMilli: 2000, price: 24000, factor: 24000),
      )!;
      expect(a.unitOff!.minor, 1200);
      expect(a.saving.minor, 2400);
    });

    test('the reduction cannot take a package below zero', () {
      final a = _apply(
        fixed,
        _line(qtyMilli: 1000, price: 1000, factor: 24000),
      )!;
      // 12.00 off a 10.00 package: net 0, saving is the whole line.
      expect(a.saving.minor, 1000);
    });
  });

  group('percent offers act on the line', () {
    test('10% of a carton line equals 10% of the same pieces', () {
      final carton = _apply(
        percent,
        _line(qtyMilli: 2000, price: 24000, factor: 24000),
      )!;
      final pieces = _apply(percent, _line(qtyMilli: 48000, price: 1000))!;
      expect(carton.saving.minor, 4800);
      expect(carton.saving.minor, pieces.saving.minor);
      expect(carton.discount, const Bp(1000));
    });

    test('Buy 1 Get 1 is 50% of the whole line, any packaging', () {
      final a = _apply(bogo, _line(qtyMilli: 1000, price: 6000, factor: 6000))!;
      expect(a.discount, const Bp(5000));
      expect(a.saving.minor, 3000);
    });
  });

  test('a free-item tier counts cart value, so a carton needs no rule', () {
    final gift = Offer(
      id: 't',
      kind: OfferKind.giftTier,
      name: 'Spend 200',
      minCart: const Money(20000, _inr),
      gift: _gift(),
    );
    final res = _engine.resolve(
      lines: [_line(qtyMilli: 1000, price: 24000, factor: 24000)],
      offers: [gift],
      now: _now,
      currency: _inr,
    );
    expect(res.gifts.single.unlocked, isTrue); // 1 carton = 240.00 >= 200.00
  });
}

Product _gift() => const Product(
  id: 99,
  name: 'Gift',
  code: 'G',
  barcode: 'G',
  price: Money(4000, _inr),
  category: 'c',
  sub: 's',
  stock: 5,
  gst: Bp(1800),
  image: -1,
  favourite: false,
);
