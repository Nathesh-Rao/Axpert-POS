import '../../../../core/services/packaging/packaging_service.dart';
import '../../../../core/services/pricing/basis_points.dart';
import '../../../../core/services/pricing/currency.dart';
import '../../../../core/services/pricing/money.dart';
import '../../../../core/services/pricing/qty.dart';
import '../../../../core/services/pricing/rational.dart';
import '../../../products/domain/entities/product.dart';
import '../entities/offer.dart';

/// What the engine needs to know about one cart line.
class OfferLine {
  const OfferLine({
    required this.productId,
    required this.qty,
    required this.price,
    required this.manualDiscount,
    this.packageFactorMilli = 1000,
  });

  final int productId;
  final Qty qty;
  final Money price;
  final Bp manualDiscount;

  /// Base units per package (milli) when the line is sold in a packaging
  /// (DEC-151), 1000 for the base unit. `qty` and `price` are then per
  /// package; a fixed-amount offer (per base unit) is scaled by this factor.
  final int packageFactorMilli;
}

/// The automatic offer applied to one line.
class AppliedOffer {
  const AppliedOffer({
    required this.kind,
    required this.offerId,
    required this.name,
    required this.discount,
    required this.unitOff,
    required this.saving,
  });

  final OfferKind kind;
  final String offerId;
  final String name;

  /// Percent off the line (promotion and percent discount), else zero.
  final Bp discount;

  /// Fixed per-unit reduction (fixed discount), else null.
  final Money? unitOff;

  /// Saving on this line, rounded half-up for display.
  final Money saving;
}

class GiftRow {
  const GiftRow({
    required this.offer,
    required this.product,
    required this.unlocked,
    required this.remaining,
  });

  final Offer offer;
  final Product product;
  final bool unlocked;

  /// Amount still to add to unlock (rounded up); zero when unlocked.
  final Money remaining;
}

class OfferResolution {
  const OfferResolution({
    required this.lines,
    required this.gifts,
    required this.cartValue,
    required this.saving,
  });

  static OfferResolution none(Currency currency, int lineCount) =>
      OfferResolution(
        lines: List<AppliedOffer?>.filled(lineCount, null),
        gifts: const <GiftRow>[],
        cartValue: Money.zero(currency),
        saving: Money.zero(currency),
      );

  /// Aligned with the input lines; null where no offer applies.
  final List<AppliedOffer?> lines;
  final List<GiftRow> gifts;

  /// Sum of line nets after offers and manual line discounts, before the bill
  /// discount, points and tax (rounded half-up for display).
  final Money cartValue;

  /// Total offer saving on lines (rounded half-up for display).
  final Money saving;

  Iterable<GiftRow> get unlockedGifts => gifts.where((g) => g.unlocked);
}

/// Plain Dart. Resolves the automatic offers of a cart. Exact [Rational] math;
/// the pricing service does the one rounding of the totals.
class OfferEngine {
  const OfferEngine();

  static final Rational _tenThousand = Rational.fromInt(10000);
  static final Rational _thousand = Rational.fromInt(1000);

  OfferResolution resolve({
    required List<OfferLine> lines,
    required List<Offer> offers,
    required DateTime now,
    required Currency currency,
    String? storeId,
  }) {
    final active = <Offer>[
      for (final o in offers)
        if (o.isCurrent(now) &&
            (o.storeId == null || o.storeId == storeId) &&
            _currencyOk(o, currency))
          o,
    ];
    if (active.isEmpty) return OfferResolution.none(currency, lines.length);

    final applied = <AppliedOffer?>[];
    var net = Rational.zero;
    var saving = Rational.zero;
    for (final line in lines) {
      final qty = Rational(BigInt.from(line.qty.milli)) / _thousand;
      final gross = qty * Rational.fromInt(line.price.minor);
      AppliedOffer? offer;
      var lineNet = gross * (Rational.one - _bp(line.manualDiscount));
      if (line.manualDiscount == Bp.zero) {
        final pick = _pick(active, line.productId);
        if (pick != null) {
          final result = _apply(pick, line, qty, gross, currency);
          offer = result.$1;
          lineNet = result.$2;
          saving += gross - lineNet;
        }
      }
      applied.add(offer);
      net += lineNet;
    }

    final gifts = <GiftRow>[];
    final tiers = active.where((o) => o.kind == OfferKind.giftTier).toList()
      ..sort((a, b) {
        final byMin = a.minCart!.minor.compareTo(b.minCart!.minor);
        return byMin != 0 ? byMin : a.name.compareTo(b.name);
      });
    for (final tier in tiers) {
      final gift = tier.gift;
      final min = tier.minCart;
      if (gift == null || min == null) continue;
      if (!_giftInStock(gift, lines)) continue;
      final threshold = Rational.fromInt(min.minor);
      final unlocked = net >= threshold;
      final missing = threshold - net;
      gifts.add(
        GiftRow(
          offer: tier,
          product: gift,
          unlocked: unlocked,
          remaining: Money(unlocked ? 0 : _ceil(missing).toInt(), currency),
        ),
      );
    }

    return OfferResolution(
      lines: applied,
      gifts: gifts,
      cartValue: Money(net.roundHalfUp().toInt(), currency),
      saving: Money(saving.roundHalfUp().toInt(), currency),
    );
  }

  bool _currencyOk(Offer o, Currency currency) =>
      (o.fixedOff == null || o.fixedOff!.currency == currency) &&
      (o.minCart == null || o.minCart!.currency == currency);

  /// Promotion beats discount; inside a kind the higher priority wins, then
  /// the larger percent.
  Offer? _pick(List<Offer> active, int productId) {
    Offer? best;
    for (final o in active) {
      if (o.productId != productId) continue;
      if (o.kind != OfferKind.promotion && o.kind != OfferKind.discount) {
        continue;
      }
      if (best == null || _better(o, best)) best = o;
    }
    return best;
  }

  bool _better(Offer a, Offer b) {
    final rank = (a.kind == OfferKind.promotion ? 1 : 0).compareTo(
      b.kind == OfferKind.promotion ? 1 : 0,
    );
    if (rank != 0) return rank > 0;
    if (a.priority != b.priority) return a.priority > b.priority;
    return (a.percent?.value ?? 0) > (b.percent?.value ?? 0);
  }

  (AppliedOffer, Rational) _apply(
    Offer offer,
    OfferLine line,
    Rational qty,
    Rational gross,
    Currency currency,
  ) {
    Rational net;
    Bp bp = Bp.zero;
    Money? unitOff;
    if (offer.fixedOff != null && offer.percent == null) {
      unitOff = Money(
        const PackagingService().unitOffForPackaging(
          offer.fixedOff!.minor,
          line.packageFactorMilli,
        ),
        currency,
      );
      net =
          qty *
          Rational.max(
            Rational.zero,
            Rational.fromInt(line.price.minor - unitOff.minor),
          );
    } else {
      bp = (offer.percent ?? Bp.zero).clamp(Bp.zero, Bp.full);
      net = gross * (Rational.one - _bp(bp));
    }
    return (
      AppliedOffer(
        kind: offer.kind,
        offerId: offer.id,
        name: offer.name,
        discount: bp,
        unitOff: unitOff,
        saving: Money((gross - net).roundHalfUp().toInt(), currency),
      ),
      net,
    );
  }

  /// A gift is offered only when it is in stock and is not already a paid
  /// line (a sale keeps one line per product).
  bool _giftInStock(Product gift, List<OfferLine> lines) {
    for (final l in lines) {
      if (l.productId == gift.id) return false;
    }
    return gift.stock >= 1;
  }

  Rational _bp(Bp b) => Rational(BigInt.from(b.value)) / _tenThousand;

  BigInt _ceil(Rational r) => -(-r).floor();
}
