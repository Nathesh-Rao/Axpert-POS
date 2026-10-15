import '../entities/offer.dart';
import '../entities/offer_draft.dart';

enum OfferIssue {
  nameRequired,
  valueInvalid,
  minCartInvalid,
  dateOrder,
  priorityInvalid,
}

/// Rules of one offer in the form, plain Dart. The engine rules (no
/// stacking, promotion over discount) are the engine's; this only checks the
/// data can be stored (the table's CHECK) and makes sense.
class OfferDraftRules {
  const OfferDraftRules();

  List<OfferIssue> validate(OfferDraft d) {
    final issues = <OfferIssue>[];
    if (d.name.trim().isEmpty) issues.add(OfferIssue.nameRequired);
    switch (d.kind) {
      case OfferKind.discount:
        final percent = d.percentBp;
        final fixed = d.fixedMinor;
        final ok = (percent == null) != (fixed == null);
        if (!ok ||
            (percent != null && (percent < 1 || percent > 10000)) ||
            (fixed != null && fixed < 1)) {
          issues.add(OfferIssue.valueInvalid);
        }
      case OfferKind.promotion:
        final percent = d.percentBp;
        if (percent == null || percent < 1 || percent > 10000) {
          issues.add(OfferIssue.valueInvalid);
        }
      case OfferKind.giftTier:
        if ((d.minCartMinor ?? 0) < 1) issues.add(OfferIssue.minCartInvalid);
    }
    if (d.startsAt != null &&
        d.endsAt != null &&
        d.endsAt!.isBefore(d.startsAt!)) {
      issues.add(OfferIssue.dateOrder);
    }
    if (d.priority < 0) issues.add(OfferIssue.priorityInvalid);
    return issues;
  }
}

/// Which active offers of one product compete (DEC-153): two active offers of
/// the same family whose date windows intersect. The engine applies only one
/// of them (promotion over discount, then priority), so the form warns.
abstract final class OfferOverlap {
  /// Indices of [offers] that overlap another active offer.
  static Set<int> conflicting(List<OfferDraft> offers) {
    final result = <int>{};
    for (var i = 0; i < offers.length; i++) {
      for (var j = i + 1; j < offers.length; j++) {
        final a = offers[i];
        final b = offers[j];
        if (!a.active || !b.active) continue;
        if (_family(a.kind) != _family(b.kind)) continue;
        if (_windowsIntersect(a, b)) {
          result
            ..add(i)
            ..add(j);
        }
      }
    }
    return result;
  }

  /// Discounts and promotions compete on the product; tiers with the same
  /// gift compete among themselves.
  static int _family(OfferKind kind) => kind == OfferKind.giftTier ? 1 : 0;

  static bool _windowsIntersect(OfferDraft a, OfferDraft b) {
    final startsAfterEnd =
        a.startsAt != null &&
        b.endsAt != null &&
        a.startsAt!.isAfter(b.endsAt!);
    final endsBeforeStart =
        a.endsAt != null &&
        b.startsAt != null &&
        a.endsAt!.isBefore(b.startsAt!);
    return !startsAfterEnd && !endsBeforeStart;
  }
}
