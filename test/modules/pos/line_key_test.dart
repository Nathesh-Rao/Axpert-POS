// DEC-154: a line is keyed by (product, packaging). Merge and split rules,
// stock across lines, old JSON, offers per packaging, refunds and held bills.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/packaging/packaging_ref.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/pricing_models.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/features/offers/domain/entities/offer.dart';
import 'package:pos_application/features/offers/domain/services/offer_engine.dart';
import 'package:pos_application/features/products/domain/entities/product.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/held_bill.dart';
import 'package:pos_application/modules/pos/models/line_key.dart';
import 'package:pos_application/modules/pos/services/checkout_service.dart';
import 'package:pos_application/modules/pos/services/hold_recall_service.dart';
import 'package:pos_application/modules/returns/models/refund_request.dart';
import 'package:pos_application/modules/returns/services/refund_service.dart';
import 'package:pos_application/modules/sales/models/sale.dart';

import '../../support/test_tax.dart';

const _inr = CurrencyRegistry.inr;
Money inr(int minor) => Money(minor, _inr);

Product cola({int stock = 100}) => Product(
  id: 1,
  name: 'Cola',
  code: 'C1',
  barcode: 'B1',
  price: inr(1000),
  category: 'Drinks',
  sub: 'Soft',
  stock: stock,
  gst: const Bp(0),
  image: -1,
  favourite: false,
);

const carton = PackagingRef(
  id: 'ctn',
  unitName: 'Carton',
  quantityBaseMilli: 24000,
);
const pack = PackagingRef(id: 'pk6', unitName: 'Pack', quantityBaseMilli: 6000);

Cart cartOf(Product p, {int cartons = 0, int pieces = 0}) {
  var c = Cart.empty;
  for (var i = 0; i < pieces; i++) {
    c = c.addItem(p);
  }
  for (var i = 0; i < cartons; i++) {
    c = c.addItem(p, packaging: carton, price: inr(24000));
  }
  return c;
}

void main() {
  group('LineKey', () {
    test('base and packaged keys, string form and parse', () {
      expect(const LineKey(1), const LineKey.base(1));
      expect(const LineKey(1), isNot(const LineKey(1, 'ctn')));
      expect(const LineKey(12).text, '12');
      expect(const LineKey(12, 'ctn').text, '12|ctn');
      expect(LineKey.parse('12'), const LineKey(12));
      expect(LineKey.parse('12|ctn'), const LineKey(12, 'ctn'));
    });
  });

  group('merge and split', () {
    test('a carton does not merge into pieces: two lines', () {
      final c = cartOf(cola(), pieces: 3, cartons: 2);
      expect(c.lines.length, 2);
      expect(c.lineOf(const LineKey(1))!.qty, Qty.units(3));
      expect(c.lineOf(const LineKey(1, 'ctn'))!.qty, Qty.units(2));
      expect(c.lineOf(const LineKey(1, 'ctn'))!.price, inr(24000));
    });

    test('the same unit merges, removal and restore work per line', () {
      var c = cartOf(cola(), pieces: 2, cartons: 1);
      c = c.addItem(cola(), packaging: carton, price: inr(24000));
      expect(c.lines.length, 2);
      final line = c.lineOf(const LineKey(1, 'ctn'))!;
      expect(line.qty, Qty.units(2));
      final removed = c.removeLine(line.key);
      expect(removed.lines.single.key, const LineKey(1));
      expect(removed.restoreLine(line).lines.length, 2);
      expect(
        identical(removed.restoreLine(line).restoreLine(line), removed),
        isFalse,
      );
    });

    test(
      'changeUnit moves the quantity, resets price, merges into the target',
      () {
        var c = cartOf(cola(), pieces: 3);
        c = c.changeUnit(const LineKey(1), carton, inr(24000));
        expect(c.lines.single.key, const LineKey(1, 'ctn'));
        expect(c.lines.single.qty, Qty.units(3));
        expect(c.lines.single.discount, Bp.zero);
        c = c.addItem(cola());
        c = c.changeUnit(const LineKey(1), carton, inr(24000));
        expect(c.lines.single.qty, Qty.units(4));
        final back = c.changeUnit(const LineKey(1, 'ctn'), null, inr(1000));
        expect(back.lines.single.key, const LineKey(1));
      },
    );
  });

  group('stock across lines (base units)', () {
    test('2 cartons + 3 pieces against a balance of 50', () {
      final p = cola(stock: 50);
      var c = cartOf(p, cartons: 2, pieces: 2);
      expect(c.baseQtyOf(1), Qty.units(50));
      expect(identical(c.addItem(p), c), isTrue, reason: 'no piece left');
      expect(
        identical(c.addItem(p, packaging: carton, price: inr(24000)), c),
        isTrue,
      );
      c = c.setQty(const LineKey(1, 'ctn'), Qty.units(5));
      expect(
        c.lineOf(const LineKey(1, 'ctn'))!.qty,
        Qty.units(2),
        reason: '48 + 2',
      );
    });

    test('changeUnit is blocked when the new unit does not fit', () {
      final c = cartOf(cola(stock: 30), pieces: 25);
      expect(
        identical(c.changeUnit(const LineKey(1), carton, inr(24000)), c),
        isTrue,
      );
    });

    CheckoutResult run(
      Cart cart, {
      bool allowNegative = false,
      int stock = 50,
    }) => const CheckoutService().complete(
      cart: cart,
      totals: testIndiaPricing.calculate(
        CartInput(
          lines: <LineInput>[
            for (final l in cart.lines)
              LineInput(
                qty: l.qty,
                price: l.price,
                taxRate: l.product.gst,
                discount: l.discount,
              ),
          ],
          billDiscount: cart.billDiscount,
          pointsToRedeem: 0,
          availablePoints: 0,
        ),
      ),
      customer: const Customer(
        id: Customer.walkInId,
        name: 'Walk-in Customer',
        phone: '',
        email: '',
        member: '',
        points: 0,
      ),
      stockOf: (id) => Qty.units(stock),
      salesCount: 0,
      store: 'S',
      now: DateTime.utc(2026, 10, 8),
      mode: SaleMode.cash,
      tendered: inr(100000),
      allowNegativeStock: allowNegative,
    );

    test(
      'checkout sums the lines, blocks, and deducts base units per product',
      () {
        final c = cartOf(cola(), cartons: 2, pieces: 3);
        final ok = run(c, stock: 100) as CheckoutDone;
        expect(ok.stockDeltas, <int, int>{1: 51});
      },
      skip: false,
    );

    test('checkout blocks unless the store allows negative stock', () {
      final c = cartOf(cola(), cartons: 2, pieces: 3); // 51 base units
      expect(run(c, stock: 50), isA<CheckoutStockChanged>());
      expect(run(c, stock: 50, allowNegative: true), isA<CheckoutDone>());
      expect(run(c, stock: 51), isA<CheckoutDone>());
    });
  });

  group('persistence and old data', () {
    test('base-only JSON is byte-identical and old carts load', () {
      final c = cartOf(cola(), pieces: 2);
      final json = jsonEncode(c.toJson());
      expect(json.contains('packaging'), isFalse);
      expect(
        jsonEncode(
          Cart.fromJson(jsonDecode(json) as Map<String, dynamic>).toJson(),
        ),
        json,
      );
      final held = HeldBill(ref: 'H1', time: 't', cart: c);
      expect(
        HeldBill.fromJson(held.toJson()).cart.lines.single.packaging,
        isNull,
      );
    });

    test('a packaged cart round-trips with its packaging', () {
      final c = cartOf(cola(), pieces: 1, cartons: 2);
      final back = Cart.fromJson(
        jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>,
      );
      expect(back.lines.map((l) => l.key).toList(), <LineKey>[
        const LineKey(1),
        const LineKey(1, 'ctn'),
      ]);
    });

    test('Sale.returned: base keys stay plain ids in JSON', () {
      expect(
        <String>[
          for (final k in <LineKey>[const LineKey(2), const LineKey(2, 'ctn')])
            k.text,
        ],
        <String>['2', '2|ctn'],
      );
    });

    test('recall clamps lines against the shared base stock, in order', () {
      final bill = const HoldRecallService().hold(
        cartOf(cola(), pieces: 5, cartons: 2),
        DateTime.utc(2026, 10, 8),
      );
      final out = const HoldRecallService().recall(
        bill,
        (id) => cola(stock: 30),
      );
      expect(out.cart.lines.length, 2);
      expect(out.cart.lineOf(const LineKey(1))!.qty, Qty.units(5));
      expect(
        out.cart.lineOf(const LineKey(1, 'ctn'))!.qty,
        Qty.units(1),
        reason: '25 left, one carton fits',
      );
    });
  });

  group('offers per packaging', () {
    const engine = OfferEngine();
    OfferResolution resolve(List<OfferLine> lines, List<Offer> offers) =>
        engine.resolve(
          lines: lines,
          offers: offers,
          now: DateTime.utc(2026, 10, 8),
          currency: _inr,
        );
    OfferLine line(int qty, int price, {String? pk, int factor = 1000}) =>
        OfferLine(
          productId: 1,
          packagingId: pk,
          qty: Qty.units(qty),
          price: inr(price),
          manualDiscount: Bp.zero,
          packageFactorMilli: factor,
        );

    test('percent applies to each line of the product', () {
      final r = resolve(
        <OfferLine>[line(3, 1000), line(2, 24000, pk: 'ctn', factor: 24000)],
        const <Offer>[
          Offer(
            id: 'd',
            kind: OfferKind.discount,
            name: '20%',
            productId: 1,
            percent: Bp(2000),
          ),
        ],
      );
      expect(r.lines.map((o) => o?.discount), <Bp?>[
        const Bp(2000),
        const Bp(2000),
      ]);
      expect(r.saving, inr(600 + 9600));
    });

    test('Buy 1 Get 1 puts the whole line at 50 %, per line', () {
      final r = resolve(
        <OfferLine>[line(3, 1000), line(2, 24000, pk: 'ctn', factor: 24000)],
        const <Offer>[
          Offer(
            id: 'b',
            kind: OfferKind.promotion,
            name: 'BOGO',
            productId: 1,
            percent: Bp(5000),
          ),
        ],
      );
      expect(r.lines[1]!.saving, inr(24000));
      expect(r.cartValue, inr(1500 + 24000));
    });

    test('a fixed offer is per base unit and scales with the package', () {
      final r = resolve(
        <OfferLine>[line(2, 24000, pk: 'ctn', factor: 24000)],
        <Offer>[
          Offer(
            id: 'f',
            kind: OfferKind.discount,
            name: '1 off',
            productId: 1,
            fixedOff: inr(100),
          ),
        ],
      );
      expect(r.lines.single!.unitOff, inr(2400));
      expect(r.cartValue, inr(2 * (24000 - 2400)));
    });

    test('a gift is blocked by a base line, not by a packaged line', () {
      final gift = cola();
      final tier = Offer(
        id: 't',
        kind: OfferKind.giftTier,
        name: 'Gift',
        minCart: inr(100),
        gift: gift,
      );
      expect(resolve(<OfferLine>[line(1, 1000)], <Offer>[tier]).gifts, isEmpty);
      expect(
        resolve(
          <OfferLine>[line(1, 24000, pk: 'ctn', factor: 24000)],
          <Offer>[tier],
        ).gifts.length,
        1,
      );
    });
  });

  group('refund by line', () {
    Sale soldSale() {
      final cart = cartOf(cola(), pieces: 3, cartons: 2);
      return Sale(
        number: 'AX000001',
        date: DateTime.utc(2026, 10, 8).toIso8601String(),
        store: 'S',
        customer: 'W',
        cart: cart,
        totals: SaleTotals(
          items: 2,
          qty: Qty.units(5),
          value: inr(51000),
          subtotal: inr(51000),
          discount: inr(0),
          tax: inr(0),
          points: inr(0),
          total: inr(51000),
        ),
        mode: 'Cash',
        tendered: inr(51000),
        change: inr(0),
        returned: const <LineKey, Qty>{},
      );
    }

    test('available, check and restock are per line', () {
      final sale = soldSale();
      final ctn = const LineKey(1, 'ctn');
      expect(
        RefundService.check(sale, <LineKey, Qty>{ctn: Qty.units(3)}),
        RefundCheck.exceeds,
      );
      expect(
        RefundService.check(sale, <LineKey, Qty>{ctn: Qty.units(1)}),
        RefundCheck.ok,
      );
      expect(
        RefundService.restockUnits(<LineKey, Qty>{
          ctn: Qty.units(1),
        }, sale: sale),
        <int, int>{1: 24},
      );
      expect(
        RefundService.restockUnits(<LineKey, Qty>{
          ctn: Qty.units(1),
          const LineKey(1): Qty.units(3),
        }, sale: sale),
        <int, int>{1: 27},
      );
      final after = RefundService.applyReturned(sale, <LineKey, Qty>{
        ctn: Qty.units(1),
      });
      expect(after.returned[ctn], Qty.units(1));
      expect(RefundService.available(after, after.cart.lines[1]), Qty.units(1));
      expect(RefundService.available(after, after.cart.lines[0]), Qty.units(3));
    });

    test('sale JSON keeps plain ids for base lines', () {
      final sale = soldSale().copyWith(
        returned: <LineKey, Qty>{
          const LineKey(1): Qty.units(1),
          const LineKey(1, 'ctn'): Qty.units(1),
        },
      );
      final json = sale.toJson()['returned'] as Map<String, dynamic>;
      expect(json.keys.toList(), <String>['1', '1|ctn']);
      expect(Sale.fromJson(sale.toJson()).returned, sale.returned);
    });
  });
}
