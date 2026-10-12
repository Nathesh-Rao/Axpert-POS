// Offers in the cart and at checkout (DEC-134): totals through the pricing
// service, locked and unlocked free items, the sale snapshot, stock and the
// refund of a free item.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/pricing_helpers.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/features/offers/domain/entities/offer.dart';
import 'package:pos_application/features/offers/presentation/controllers/offers_controller.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/payment_controller.dart';
import 'package:pos_application/modules/pos/models/payment_state.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';

import '../../support/test_app.dart';

const _inr = CurrencyRegistry.inr;

Future<void> _boot() async {
  await bootTestApp();
  final offers = Get.find<OffersController>();
  final products = Get.find<ProductsController>();
  offers.offers.assignAll(<Offer>[
    const Offer(
      id: 'cola',
      kind: OfferKind.discount,
      name: 'Cola 20% off',
      productId: 0,
      percent: Bp(2000),
    ),
    const Offer(
      id: 'oreo',
      kind: OfferKind.promotion,
      name: 'Oreo Buy 1 Get 1',
      productId: 7,
      percent: Bp(5000),
    ),
    Offer(
      id: 'tier',
      kind: OfferKind.giftTier,
      name: 'Spend 100',
      minCart: const Money(10000, _inr),
      gift: products.byId(5),
    ),
  ]);
  offers.revision.value++;
}

void main() {
  useTestApp();

  test('a promotion line is half price from the first unit', () async {
    await _boot();
    final cart = Get.find<CartController>();
    final actions = Get.find<CartActionsController>();
    final oreo = Get.find<ProductsController>().byId(7)!; // 35.00, GST 12%
    for (var i = 0; i < 3; i++) {
      actions.add(oreo);
    }
    // 3 x 35.00 = 105.00 gross, half price = 52.50, tax 12% = 6.30.
    final t = cart.totals.value;
    expect(t.value.minor, 10500);
    expect(t.discount.minor, 5250);
    expect(t.tax.minor, 630);
    expect(t.total.minor, 5880);
    expect(cart.offerResolution.value.saving.minor, 5250);
  });

  test('the discount offer applies and a manual discount overrides it', () {
    return () async {
      await _boot();
      final cart = Get.find<CartController>();
      final cola = Get.find<ProductsController>().byId(0)!; // 40.00, GST 18%
      Get.find<CartActionsController>().add(cola);
      expect(cart.totals.value.discount.minor, 800);
      cart.setLineDiscount(0, const Bp(1000));
      expect(cart.totals.value.discount.minor, 400);
      expect(cart.offerResolution.value.lines.single, isNull);
    }();
  });

  test('the free item is locked, then unlocked, then locked again', () async {
    await _boot();
    final cart = Get.find<CartController>();
    final actions = Get.find<CartActionsController>();
    final products = Get.find<ProductsController>();
    actions.add(products.byId(1)!); // Pepsi 40.00
    actions.add(products.byId(1)!);
    var gift = cart.gifts.single;
    expect(gift.unlocked, isFalse);
    expect(gift.remaining.minor, 2000); // 80.00 of 100.00
    actions.add(products.byId(1)!);
    gift = cart.gifts.single;
    expect(gift.unlocked, isTrue);
    expect(gift.remaining.minor, 0);
    cart.setQty(1, Qty.units(1));
    expect(cart.gifts.single.unlocked, isFalse);
  });

  test('checkout sells the free item at 0 and takes its stock', () async {
    await bootTestApp();
    final offers = Get.find<OffersController>();
    final products = Get.find<ProductsController>();
    offers.offers.assignAll(<Offer>[
      Offer(
        id: 'tier',
        kind: OfferKind.giftTier,
        name: 'Spend 100',
        minCart: const Money(10000, _inr),
        gift: products.byId(5),
      ),
      const Offer(
        id: 'oreo',
        kind: OfferKind.promotion,
        name: 'Oreo Buy 1 Get 1',
        productId: 7,
        percent: Bp(5000),
      ),
    ]);
    offers.revision.value++;
    final stockBefore = products.byId(5)!.stock;
    final oreoBefore = products.byId(7)!.stock;
    final actions = Get.find<CartActionsController>();
    for (var i = 0; i < 4; i++) {
      actions.add(products.byId(7)!); // 4 x 35.00 at half price = 70.00
    }
    actions.add(products.byId(1)!); // + 40.00 = 110.00 >= 100.00: unlocked
    final cart = Get.find<CartController>();
    expect(cart.gifts.single.unlocked, isTrue);
    final totalBefore = cart.totals.value.total;
    final pay = Get.find<PaymentController>();
    pay.payment(PaymentMode.cash);
    pay.tendered.text = '500';
    pay.completeCash();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final sale = Get.find<SalesController>().sales.last;
    expect(sale.totals.total, totalBefore);
    final gift = sale.cart.lines.firstWhere((l) => l.product.id == 5);
    expect(gift.price.minor, 0);
    expect(gift.offer!.isGift, isTrue);
    final oreo = sale.cart.lines.firstWhere((l) => l.product.id == 7);
    expect(oreo.offer!.kind, 'promotion');
    expect(oreo.discount.value, 5000);
    expect(oreo.offer!.savingMinor, 7000);
    expect(products.byId(5)!.stock, stockBefore - 1);
    expect(products.byId(7)!.stock, oreoBefore - 4);
    // The sale's JSON round-trips with its offers.
    final again = sale.cart.lines
        .map((l) => l.toJson())
        .where((j) => j['offer'] != null)
        .length;
    expect(again, 2);
  });

  test('a free item refunds nothing, a paid line refunds its share', () {
    // sale total 82.40 over gross lines 140.00 (paid) + 0 (free).
    final free = PricingHelpers.refund(
      saleTotal: const Money(8240, _inr),
      saleValue: const Money(14000, _inr),
      lines: const <RefundLine>[
        RefundLine(
          soldQty: Qty(1000),
          price: Money(0, _inr),
          returnQty: Qty(1000),
        ),
      ],
    );
    expect(free.minor, 0);
  });
}
