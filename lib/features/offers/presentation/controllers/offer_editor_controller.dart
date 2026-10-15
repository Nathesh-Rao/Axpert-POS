import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/pricing/basis_points.dart';
import '../../../../core/services/pricing/currency.dart';
import '../../../../core/services/pricing/money.dart';
import '../../../../core/services/pricing/qty.dart';
import '../../../../core/utils/decimal_input.dart';
import '../../../../core/utils/decimal_text.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../products/domain/entities/product.dart';
import '../../domain/entities/offer.dart';
import '../../domain/entities/offer_draft.dart';
import '../../domain/services/offer_draft_rules.dart';
import '../../domain/services/offer_engine.dart';
import 'offers_controller.dart';

/// How a discount is given.
enum DiscountMode { percent, amount }

/// What the tile would show for the offer being edited.
class OfferPreview {
  const OfferPreview({required this.kind, required this.badge, this.text});

  final OfferKind kind;
  final String badge;

  /// "₹100.00 to ₹80.00", or the free-item line.
  final String? text;
}

/// The "Offers & promotions" section of the product form (DEC-153): the
/// product's offers as a list plus one inline editor. Offers are saved with
/// the product (same transaction), not on their own. The preview uses the
/// real [OfferEngine] and the tile's badge builder, no separate math.
class OfferEditorController {
  OfferEditorController({
    required this.currency,
    required this.basePriceMinor,
    required this.productId,
    required this.productName,
    this.now,
  });

  final Currency Function() currency;

  /// The base price typed in the form; null while it is not a number.
  final int? Function() basePriceMinor;

  /// Legacy id of the edited product (-1 while it is new).
  final int Function() productId;
  final String Function() productName;
  final DateTime Function()? now;

  final OfferEngine _engine = const OfferEngine();
  final OfferDraftRules _rules = const OfferDraftRules();

  final RxList<OfferDraft> offers = <OfferDraft>[].obs;

  /// The editor is open; [editingIndex] is the list place, null = a new one.
  final RxBool open = false.obs;
  final Rxn<int> editingIndex = Rxn<int>();
  final Rx<OfferKind> kind = OfferKind.discount.obs;
  final Rx<DiscountMode> mode = DiscountMode.percent.obs;
  final RxBool active = true.obs;
  final RxMap<String, String> errors = <String, String>{}.obs;
  final RxInt tick = 0.obs;

  final TextEditingController name = TextEditingController();
  final TextEditingController value = TextEditingController();
  final TextEditingController minCart = TextEditingController();
  final TextEditingController starts = TextEditingController();
  final TextEditingController ends = TextEditingController();
  final TextEditingController priority = TextEditingController(text: '0');

  List<TextEditingController> get _boxes => [
    name,
    value,
    minCart,
    starts,
    ends,
    priority,
  ];

  /// Starts listening to the boxes (call once after creating it).
  void init() {
    for (final c in _boxes) {
      c.addListener(() => tick.value++);
    }
  }

  void load(List<OfferDraft> saved) => offers.assignAll(saved);

  void beginAdd() {
    editingIndex.value = null;
    kind.value = OfferKind.discount;
    mode.value = DiscountMode.percent;
    active.value = true;
    for (final c in _boxes) {
      c.clear();
    }
    priority.text = '0';
    errors.clear();
    open.value = true;
  }

  void beginEdit(int index) {
    final o = offers[index];
    editingIndex.value = index;
    kind.value = o.kind;
    active.value = o.active;
    name.text = o.name;
    final bp = o.percentBp;
    final fixed = o.fixedMinor;
    mode.value = fixed != null ? DiscountMode.amount : DiscountMode.percent;
    value.text = o.kind == OfferKind.promotion
        ? ''
        : fixed != null
        ? DecimalText.fixed(fixed, currency().exponent)
        : (bp == null ? '' : DecimalText.scaled(bp, 2));
    minCart.text = o.minCartMinor == null
        ? ''
        : DecimalText.fixed(o.minCartMinor!, currency().exponent);
    starts.text = _dateText(o.startsAt);
    ends.text = _dateText(o.endsAt);
    priority.text = '${o.priority}';
    errors.clear();
    open.value = true;
  }

  void cancel() {
    open.value = false;
    errors.clear();
  }

  void remove(int index) {
    offers.removeAt(index);
    open.value = false;
  }

  void toggle(int index, bool on) =>
      offers[index] = offers[index].copyWith(active: on);

  /// Enter and "Add offer": validates and puts the offer in the list.
  bool apply() {
    final draft = _candidate(errorsOut: true);
    if (draft == null) return false;
    final at = editingIndex.value;
    if (at == null) {
      offers.add(draft);
    } else {
      offers[at] = draft;
    }
    open.value = false;
    return true;
  }

  static String _dateText(DateTime? d) => d == null
      ? ''
      : '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';

  /// `YYYY-MM-DD` as a UTC date; null for blank, [bad] set for other text.
  static DateTime? _date(String text, void Function() bad, {bool end = false}) {
    final t = text.trim();
    if (t.isEmpty) return null;
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(t);
    final parsed = m == null
        ? null
        : DateTime.utc(
            int.parse(m.group(1)!),
            int.parse(m.group(2)!),
            int.parse(m.group(3)!),
          );
    if (parsed == null || _dateText(parsed) != t) {
      bad();
      return null;
    }
    // An end date covers its whole day.
    return end
        ? parsed.add(const Duration(hours: 23, minutes: 59, seconds: 59))
        : parsed;
  }

  /// The offer in the editor, or null when it is not valid ([errorsOut]
  /// fills [errors] with the messages).
  OfferDraft? _candidate({bool errorsOut = false}) {
    final s = AppStrings.current;
    final exp = currency().exponent;
    final found = <String, String>{};
    var bad = false;
    final from = _date(starts.text, () {
      found['starts'] = s.offerErrDate();
      bad = true;
    });
    final to = _date(ends.text, () {
      found['ends'] = s.offerErrDate();
      bad = true;
    }, end: true);
    final prio = int.tryParse(priority.text.trim());
    int? percent;
    int? fixed;
    int? min;
    switch (kind.value) {
      case OfferKind.discount:
        if (mode.value == DiscountMode.percent) {
          percent = DecimalInput.tryScaled(value.text, 2);
        } else {
          fixed = DecimalInput.tryScaled(value.text, exp);
        }
      case OfferKind.promotion:
        percent = 5000;
      case OfferKind.giftTier:
        min = DecimalInput.tryScaled(minCart.text, exp);
    }
    final label = _autoName(percent, fixed, min);
    final draft = OfferDraft(
      id: editingIndex.value == null ? null : offers[editingIndex.value!].id,
      kind: kind.value,
      name: name.text.trim().isEmpty ? label : name.text.trim(),
      percentBp: percent,
      fixedMinor: fixed,
      minCartMinor: min,
      startsAt: from,
      endsAt: to,
      active: active.value,
      priority: prio ?? 0,
    );
    if (prio == null || prio < 0) found['priority'] = s.offerErrPriority();
    for (final issue in _rules.validate(draft)) {
      switch (issue) {
        case OfferIssue.nameRequired:
          found['name'] = s.offerErrName();
        case OfferIssue.valueInvalid:
          found['value'] = s.offerErrValue();
        case OfferIssue.minCartInvalid:
          found['minCart'] = s.offerErrMinCart();
        case OfferIssue.dateOrder:
          found['ends'] = s.offerErrDateOrder();
        case OfferIssue.priorityInvalid:
          found['priority'] = s.offerErrPriority();
      }
    }
    if (errorsOut) errors.assignAll(found);
    return found.isEmpty && !bad ? draft : null;
  }

  String _autoName(int? percent, int? fixed, int? min) {
    final s = AppStrings.current;
    final cur = currency();
    return switch (kind.value) {
      OfferKind.promotion => s.offerBadgeBogo(),
      OfferKind.discount =>
        percent != null
            ? s.offerBadgePercent(OffersController.percentText(percent))
            : s.offerBadgeAmount(MoneyFormatter.formatMinor(fixed ?? 0, cur)),
      OfferKind.giftTier => s.offerBadgeGift(),
    };
  }

  /// A one-line summary of a saved offer for the list.
  String summary(OfferDraft o) {
    final s = AppStrings.current;
    final cur = currency();
    return switch (o.kind) {
      OfferKind.promotion => s.offerBadgeBogo(),
      OfferKind.discount =>
        o.fixedMinor != null
            ? s.offerBadgeAmount(MoneyFormatter.formatMinor(o.fixedMinor!, cur))
            : s.offerBadgePercent(
                OffersController.percentText(o.percentBp ?? 0),
              ),
      OfferKind.giftTier => s.offerPreviewGift(
        MoneyFormatter.formatMinor(o.minCartMinor ?? 0, cur),
      ),
    };
  }

  String window(OfferDraft o) {
    final s = AppStrings.current;
    final a = o.startsAt;
    final b = o.endsAt;
    if (a == null && b == null) return '';
    if (a != null && b != null) {
      return s.offerWindow(_dateText(a), _dateText(b));
    }
    return a != null
        ? s.offerWindowFrom(_dateText(a))
        : s.offerWindowUntil(_dateText(b));
  }

  /// List places whose offer overlaps another active one (also counts the
  /// one in the editor once it is valid, as [candidateOverlaps]).
  Set<int> get overlapping => OfferOverlap.conflicting(offers.toList());

  /// The offer being edited would overlap an active offer of the list.
  bool get candidateOverlaps {
    tick.value; // ignore: unnecessary_statements
    final draft = _candidate();
    if (draft == null || !draft.active) return false;
    final at = editingIndex.value;
    final others = [
      for (var i = 0; i < offers.length; i++)
        if (i != at) offers[i],
    ];
    return OfferOverlap.conflicting([...others, draft]).contains(others.length);
  }

  /// What the tile shows for the offer being edited, with the resulting
  /// price; null while the form has no price or the offer is not valid.
  OfferPreview? preview() {
    tick.value; // ignore: unnecessary_statements
    final base = basePriceMinor();
    final draft = _candidate();
    if (base == null || draft == null) return null;
    final cur = currency();
    final s = AppStrings.current;
    final product = Product(
      id: productId(),
      name: productName(),
      code: '',
      barcode: '',
      price: Money(base, cur),
      category: '',
      sub: '',
      stock: 0,
      gst: Bp.zero,
      image: -1,
      favourite: false,
    );
    // Dates are ignored: the preview shows what the offer does when it runs.
    final offer = Offer(
      id: 'preview',
      kind: draft.kind,
      name: draft.name,
      productId: draft.kind == OfferKind.giftTier ? null : product.id,
      percent: draft.percentBp == null ? null : Bp(draft.percentBp!),
      fixedOff: draft.fixedMinor == null ? null : Money(draft.fixedMinor!, cur),
      minCart: draft.minCartMinor == null
          ? null
          : Money(draft.minCartMinor!, cur),
      gift: draft.kind == OfferKind.giftTier ? product : null,
    );
    final tile = OffersController.tileFor(
      [offer],
      product,
      now?.call() ?? DateTime.now(),
    );
    if (tile == null) return null;
    if (draft.kind == OfferKind.giftTier) {
      return OfferPreview(
        kind: draft.kind,
        badge: tile.label,
        text: s.offerPreviewGift(
          MoneyFormatter.formatMinor(draft.minCartMinor ?? 0, cur),
        ),
      );
    }
    final resolution = _engine.resolve(
      lines: [
        OfferLine(
          productId: product.id,
          qty: const Qty(1000),
          price: product.price,
          manualDiscount: Bp.zero,
        ),
      ],
      offers: [offer],
      now: now?.call() ?? DateTime.now(),
      currency: cur,
    );
    return OfferPreview(
      kind: draft.kind,
      badge: tile.label,
      text: s.offerPreviewPrice(
        MoneyFormatter.format(product.price),
        MoneyFormatter.format(resolution.cartValue),
      ),
    );
  }

  void dispose() {
    for (final c in _boxes) {
      c.dispose();
    }
  }
}
