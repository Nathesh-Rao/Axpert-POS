import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/pricing/money.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/offer.dart';
import '../../domain/repositories/offer_repository.dart';

/// What a product tile shows for its offer: one badge, and for a discount the
/// struck-through original price beside the new one.
class TileOffer {
  const TileOffer({required this.kind, required this.label, this.salePrice});

  final OfferKind kind;
  final String label;

  /// The price after a discount; null for a promotion or a gift badge.
  final Money? salePrice;
}

/// The offers of the active store (permanent). Offers are loaded with the
/// session; the engine evaluates their date windows each time the cart
/// changes, tile badges are refreshed on load (DEC-134).
class OffersController extends GetxController {
  OffersController(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final OfferRepository _repository;
  final DateTime Function() _now;

  final RxList<Offer> offers = <Offer>[].obs;

  /// Bumped on every load so tiles can rebuild their badge once.
  final RxInt revision = 0.obs;

  final Map<int, TileOffer?> _tiles = <int, TileOffer?>{};

  Future<void> load(String? storeId) async {
    offers.assignAll(await _repository.load(storeId: storeId));
    _tiles.clear();
    revision.value++;
  }

  void clear() {
    offers.clear();
    _tiles.clear();
    revision.value++;
  }

  /// The badge of [product]: promotion, then discount, then gift.
  TileOffer? tileOffer(Product product) {
    if (offers.isEmpty) return null;
    return _tiles.putIfAbsent(product.id, () => _build(product));
  }

  TileOffer? _build(Product product) {
    final now = _now();
    Offer? promo;
    Offer? discount;
    Offer? gift;
    for (final o in offers) {
      if (!o.isCurrent(now)) continue;
      switch (o.kind) {
        case OfferKind.promotion:
          if (o.productId == product.id && promo == null) promo = o;
        case OfferKind.discount:
          if (o.productId == product.id &&
              (o.fixedOff == null ||
                  o.fixedOff!.currency == product.price.currency) &&
              discount == null) {
            discount = o;
          }
        case OfferKind.giftTier:
          if (o.gift?.id == product.id && gift == null) gift = o;
      }
    }
    final s = AppStrings.current;
    if (promo != null) {
      return TileOffer(kind: OfferKind.promotion, label: s.offerBadgeBogo());
    }
    if (discount != null) {
      final fixed = discount.fixedOff;
      if (fixed != null && discount.percent == null) {
        final sale = Money(
          product.price.minor > fixed.minor
              ? product.price.minor - fixed.minor
              : 0,
          product.price.currency,
        );
        return TileOffer(
          kind: OfferKind.discount,
          label: s.offerBadgeAmount(MoneyFormatter.format(fixed)),
          salePrice: sale,
        );
      }
      final bp = discount.percent!.value;
      final sale = Money(
        (product.price.minor * (10000 - bp) * 2 + 10000) ~/ 20000,
        product.price.currency,
      );
      return TileOffer(
        kind: OfferKind.discount,
        label: s.offerBadgePercent(percentText(bp)),
        salePrice: sale,
      );
    }
    if (gift != null) {
      return TileOffer(kind: OfferKind.giftTier, label: s.offerBadgeGift());
    }
    return null;
  }

  /// 2000 bp -> `20`, 1250 bp -> `12.5`, 1205 bp -> `12.05`.
  static String percentText(int bp) {
    final whole = bp ~/ 100;
    final frac = bp % 100;
    if (frac == 0) return '$whole';
    final text = frac.toString().padLeft(2, '0');
    return '$whole.${text.endsWith('0') ? text.substring(0, 1) : text}';
  }
}
