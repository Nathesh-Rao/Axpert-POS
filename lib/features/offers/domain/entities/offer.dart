import '../../../../core/services/pricing/basis_points.dart';
import '../../../../core/services/pricing/money.dart';
import '../../../products/domain/entities/product.dart';

enum OfferKind {
  discount,
  promotion,
  giftTier;

  String get code => switch (this) {
    OfferKind.discount => 'discount',
    OfferKind.promotion => 'promotion',
    OfferKind.giftTier => 'gift_tier',
  };

  static OfferKind parse(String code) => OfferKind.values.firstWhere(
    (k) => k.code == code,
    orElse: () => throw FormatException('Unknown offer kind: $code'),
  );
}

/// An automatic offer. Discount: [percent] or [fixedOff] per unit on
/// [productId]. Promotion (Buy 1 Get 1): the whole product at [percent]
/// (50 % in the demo data) from the first unit. Gift tier: [gift] is free once
/// the cart value reaches [minCart].
class Offer {
  const Offer({
    required this.id,
    required this.kind,
    required this.name,
    this.storeId,
    this.productId,
    this.percent,
    this.fixedOff,
    this.minCart,
    this.gift,
    this.startsAt,
    this.endsAt,
    this.priority = 0,
  });

  final String id;
  final OfferKind kind;
  final String name;

  /// Null = every store.
  final String? storeId;
  final int? productId;
  final Bp? percent;

  /// Fixed reduction per unit (discount only).
  final Money? fixedOff;
  final Money? minCart;
  final Product? gift;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int priority;

  bool isCurrent(DateTime now) =>
      (startsAt == null || !now.isBefore(startsAt!)) &&
      (endsAt == null || !now.isAfter(endsAt!));
}
