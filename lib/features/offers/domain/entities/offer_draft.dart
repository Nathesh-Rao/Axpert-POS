import 'offer.dart';

/// One offer of the product form (DEC-153). Percent is basis points, money is
/// minor units of the store currency. [id] is null for a new offer. A
/// discount has exactly one of [percentBp] and [fixedMinor]; a promotion is
/// always [percentBp] (5000 = Buy 1 Get 1 half price); a free-item tier has
/// [minCartMinor] and the edited product as the gift.
class OfferDraft {
  const OfferDraft({
    required this.kind,
    required this.name,
    this.id,
    this.percentBp,
    this.fixedMinor,
    this.minCartMinor,
    this.startsAt,
    this.endsAt,
    this.active = true,
    this.priority = 0,
  });

  final String? id;
  final OfferKind kind;
  final String name;
  final int? percentBp;
  final int? fixedMinor;
  final int? minCartMinor;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool active;
  final int priority;

  OfferDraft copyWith({bool? active}) => OfferDraft(
    id: id,
    kind: kind,
    name: name,
    percentBp: percentBp,
    fixedMinor: fixedMinor,
    minCartMinor: minCartMinor,
    startsAt: startsAt,
    endsAt: endsAt,
    active: active ?? this.active,
    priority: priority,
  );
}
