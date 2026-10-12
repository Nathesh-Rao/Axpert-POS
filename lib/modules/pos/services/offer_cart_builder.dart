import '../../../core/services/pricing/basis_points.dart';
import '../../../core/services/pricing/currency.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../features/offers/domain/entities/offer.dart';
import '../../../features/offers/domain/services/offer_engine.dart';
import '../models/cart.dart';
import '../models/cart_line.dart';

/// The cart as it is sold: lines carry their offer, unlocked free items are
/// added as price-0 lines (stock is taken, the receipt shows them, they
/// refund nothing). Plain Dart; the checkout and the demo seeder share it.
abstract final class OfferCartBuilder {
  static Cart asSold(Cart cart, OfferResolution res, Currency currency) {
    final lines = <CartLine>[
      for (var i = 0; i < cart.lines.length; i++)
        res.lines[i] == null
            ? cart.lines[i]
            : cart.lines[i].withOffer(lineOffer(res.lines[i]!)),
      for (final gift in res.unlockedGifts)
        CartLine(
          product: gift.product.inCurrency(currency),
          qty: Qty.units(1),
          price: Money.zero(currency),
          discount: Bp.zero,
          offer: LineOffer(
            kind: OfferKind.giftTier.code,
            name: gift.offer.name,
            savingMinor: gift.product.price.minor,
            isGift: true,
          ),
        ),
    ];
    return cart.copyWith(lines: lines);
  }

  static LineOffer lineOffer(AppliedOffer o) => LineOffer(
    kind: o.kind.code,
    name: o.name,
    savingMinor: o.saving.minor,
    discountBp: o.discount.value,
    unitOffMinor: o.unitOff?.minor,
  );
}
