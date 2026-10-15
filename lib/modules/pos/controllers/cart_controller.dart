import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/services/pricing/basis_points.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/pricing_models.dart';
import '../../../core/services/pricing/pricing_service.dart';
import '../../../core/services/pricing/tax_config.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../core/services/pricing/tax_components.dart';
import '../../../core/services/pricing/tax_split.dart';
import '../../customers/controllers/customers_controller.dart';
import '../../../features/offers/domain/services/offer_engine.dart';
import '../../../features/offers/presentation/controllers/offers_controller.dart';
import '../../../features/session/presentation/controllers/active_session.dart';
import '../../../features/products/domain/entities/product.dart';
import '../models/cart.dart';
import '../services/offer_cart_builder.dart';
import '../models/cart_line.dart';
import '../models/line_key.dart';
import '../../../core/services/packaging/packaging_ref.dart';
import '../repository/cart_repository.dart';
import '../../../core/session/session_scoped.dart';

/// Permanent cart state. Applies the reducer rules, persists the draft after
/// every change (serialised, latest state wins) and computes the totals with
/// [PricingService] once per change, never in `build`.
class CartController extends GetxController implements SessionScoped {
  CartController(
    this._repository,
    this._customers, {
    PricingService pricing = const PricingService(config: TaxConfig.none),
    ActiveSession? session,
    OffersController? offers,
    OfferEngine engine = const OfferEngine(),
    DateTime Function()? now,
  }) : _pricing = pricing,
       _session = session,
       _offers = offers,
       _engine = engine,
       _now = now ?? DateTime.now;

  final CartRepository _repository;
  final CustomersController _customers;
  final PricingService _pricing;
  final ActiveSession? _session;
  final OffersController? _offers;
  final OfferEngine _engine;
  final DateTime Function() _now;

  /// The pricing of the active store (its currency); the default service
  /// before a store is chosen.
  PricingService get _service => _session?.pricing ?? _pricing;

  final Rx<Cart> cart = Cart.empty.obs;

  /// Keys of the lines in order; changes only when lines are added, removed
  /// or reordered (the cart table listens to this, not to quantities).
  final RxList<LineKey> lineIds = <LineKey>[].obs;

  /// True while the cart has lines (changes only when that flips).
  final RxBool active = false.obs;
  late final Rx<CartTotals> totals = totalsOf(Cart.empty).obs;

  /// Offers resolved for the current cart: the offer of each line, the free
  /// item rows (locked or unlocked) and the saving (DEC-134).
  late final Rx<OfferResolution> offerResolution = OfferResolution.none(
    _service.config.currency,
    0,
  ).obs;

  /// The free item rows (locked or unlocked); assigned only when they change,
  /// so the cart list does not rebuild with every quantity.
  final RxList<GiftRow> gifts = <GiftRow>[].obs;

  final Map<LineKey, ValueNotifier<AppliedOffer?>> _offerNotifiers =
      <LineKey, ValueNotifier<AppliedOffer?>>{};

  final Map<LineKey, ValueNotifier<CartLine?>> _lineNotifiers =
      <LineKey, ValueNotifier<CartLine?>>{};
  final Map<int, ValueNotifier<ProductInCart?>> _productNotifiers =
      <int, ValueNotifier<ProductInCart?>>{};
  Future<void>? _saving;
  bool _dirty = false;

  bool get isActive => cart.value.isActive;

  Future<void> load() async {
    _apply(await _repository.load(), persist: false);
  }

  /// Loads the saved cart for the signed-in store: a cart of another store is
  /// dropped, the rest takes the store's currency (the cart is stored without
  /// one).
  Future<void> loadForSession() async {
    final session = _session;
    var loaded = await _repository.load();
    if (session != null && session.scoped) {
      final store = session.store.value;
      final currency = session.currency;
      if (store == null ||
          currency == null ||
          (loaded.isActive && loaded.storeId != store.id)) {
        loaded = Cart.empty;
        _apply(loaded, persist: true);
        return;
      }
      loaded = loaded.inCurrency(currency);
    }
    _apply(loaded, persist: false);
  }

  @override
  void onInit() {
    super.onInit();
    ever(_customers.customers, (_) => _recomputeTotals());
    final offers = _offers;
    if (offers != null) ever(offers.revision, (_) => _recomputeTotals());
  }

  /// Notifies only when the offer of the line [key] changes.
  ValueListenable<AppliedOffer?> offerListenable(LineKey key) => _offerNotifiers
      .putIfAbsent(key, () => ValueNotifier<AppliedOffer?>(_offerOf(key)));

  AppliedOffer? _offerOf(LineKey key) {
    final lines = cart.value.lines;
    final applied = offerResolution.value.lines;
    for (var i = 0; i < lines.length && i < applied.length; i++) {
      if (lines[i].key == key) return applied[i];
    }
    return null;
  }

  /// The cart as it is sold (see [OfferCartBuilder]).
  Cart get cartAsSold => OfferCartBuilder.asSold(
    cart.value,
    offerResolution.value,
    _service.config.currency,
  );

  /// Notifies only when the line [key] changes (scoped rebuilds for product
  /// cards and cart rows).
  ValueListenable<CartLine?> lineListenable(LineKey key) => _lineNotifiers
      .putIfAbsent(key, () => ValueNotifier<CartLine?>(cart.value.lineOf(key)));

  CartLine? lineOf(LineKey key) => cart.value.lineOf(key);

  /// Notifies only when what the cart holds of [productId] changes (the
  /// product tile: base-unit line, total base units, packaged lines).
  ValueListenable<ProductInCart?> productListenable(int productId) =>
      _productNotifiers.putIfAbsent(
        productId,
        () => ValueNotifier<ProductInCart?>(
          ProductInCart.of(cart.value, productId),
        ),
      );

  // ---- reducer rules (no side effects; see CartActionsController) ----

  void addItem(Product product, {PackagingRef? packaging, Money? price}) =>
      _set(cart.value.addItem(product, packaging: packaging, price: price));

  void setQty(LineKey key, Qty qty) => _set(cart.value.setQty(key, qty));

  void setPrice(LineKey key, Money price) =>
      _set(cart.value.setPrice(key, price));

  void setLineDiscount(LineKey key, Bp discount) =>
      _set(cart.value.setLineDiscount(key, discount));

  void removeLine(LineKey key) => _set(cart.value.removeLine(key));

  /// Sells the line in another unit (see [Cart.changeUnit]).
  void changeUnit(LineKey key, PackagingRef? packaging, Money price) =>
      _set(cart.value.changeUnit(key, packaging, price));

  void restoreLine(CartLine line) => _set(cart.value.restoreLine(line));

  void clear() => _set(Cart.empty);

  /// Replaces the whole cart (recall, S4).
  void replace(Cart next) => _set(next);

  void patch(Cart Function(Cart) change) => _set(change(cart.value));

  /// Waits until the pending save finished (tests, shutdown).
  Future<void> flush() async {
    while (_saving != null) {
      await _saving;
    }
  }

  void _set(Cart next) {
    if (identical(next, cart.value)) return;
    _apply(next, persist: true);
  }

  void _apply(Cart next, {required bool persist}) {
    final previous = cart.value;
    final session = _session;
    if (session != null &&
        session.scoped &&
        next.isActive &&
        next.storeId == null) {
      next = next.copyWith(storeId: session.store.value?.id);
    }
    cart.value = next;
    active.value = next.isActive;
    final ids = <LineKey>[for (final l in next.lines) l.key];
    if (!listEquals(ids, lineIds)) lineIds.assignAll(ids);
    _recomputeTotals();
    _notifyLines(previous, next);
    if (persist) _persist();
  }

  void _recomputeTotals() {
    final resolution = _resolve(cart.value);
    offerResolution.value = resolution;
    if (!_sameGifts(gifts, resolution.gifts)) gifts.assignAll(resolution.gifts);
    totals.value = _calculate(cart.value, resolution);
    for (final entry in _offerNotifiers.entries) {
      entry.value.value = _offerOf(entry.key);
    }
  }

  static bool _sameGifts(List<GiftRow> a, List<GiftRow> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].offer.id != b[i].offer.id ||
          a[i].unlocked != b[i].unlocked ||
          a[i].remaining != b[i].remaining ||
          a[i].product.id != b[i].product.id) {
        return false;
      }
    }
    return true;
  }

  OfferResolution _resolve(Cart value) {
    final currency = _service.config.currency;
    final offers = _offers?.offers;
    if (offers == null || offers.isEmpty || value.lines.isEmpty) {
      return OfferResolution.none(currency, value.lines.length);
    }
    return _engine.resolve(
      lines: <OfferLine>[
        for (final line in value.lines)
          OfferLine(
            productId: line.product.id,
            packagingId: line.packaging?.id,
            qty: line.qty,
            price: line.price,
            manualDiscount: line.discount,
            packageFactorMilli: line.packaging?.quantityBaseMilli ?? 1000,
          ),
      ],
      offers: offers,
      now: _now(),
      currency: currency,
      storeId: _session?.store.value?.id,
    );
  }

  /// Tax lines (one per component) of [t], the totals of the current cart;
  /// empty when the tax is a single line. They add up to `t.tax` exactly.
  List<TaxPart> taxPartsOf(CartTotals t) {
    final regime = _session?.regime.value;
    if (regime == null) return const <TaxPart>[];
    final lines = cart.value.lines;
    final exact = t.exact.lines;
    final shares = <TaxLineShare>[
      for (var i = 0; i < exact.length && i < lines.length; i++)
        TaxLineShare(
          tax: exact[i].tax,
          rateBp: _service.config.rateFor(lines[i].product.gst).value,
        ),
    ];
    final parts = regime.partsOf(t.tax, shares);
    return parts.length >= 2 ? parts : const <TaxPart>[];
  }

  /// The totals of any cart (held bills use their customer's points).
  CartTotals totalsOf(Cart value) => _calculate(value, _resolve(value));

  CartTotals _calculate(Cart value, OfferResolution resolution) {
    final customer = _customers.byIdOrFirst(value.customer);
    return _service.calculate(
      CartInput(
        lines: <LineInput>[
          for (var i = 0; i < value.lines.length; i++)
            LineInput(
              qty: value.lines[i].qty,
              price: value.lines[i].price,
              taxRate: _service.config.rateFor(value.lines[i].product.gst),
              discount:
                  resolution.lines[i]?.discount ?? value.lines[i].discount,
              unitOff: resolution.lines[i]?.unitOff,
            ),
        ],
        billDiscount: value.billDiscount,
        pointsToRedeem: value.points,
        availablePoints: customer?.points ?? 0,
      ),
    );
  }

  void _notifyLines(Cart before, Cart after) {
    if (_lineNotifiers.isEmpty && _productNotifiers.isEmpty) return;
    final keys = <LineKey>{
      for (final l in before.lines) l.key,
      for (final l in after.lines) l.key,
    };
    for (final key in keys) {
      _lineNotifiers[key]?.value = after.lineOf(key);
    }
    for (final id in <int>{for (final k in keys) k.productId}) {
      _productNotifiers[id]?.value = ProductInCart.of(after, id);
    }
  }

  void _persist() {
    _dirty = true;
    _saving ??= _drain();
  }

  Future<void> _drain() async {
    try {
      while (_dirty) {
        _dirty = false;
        await _repository.save(cart.value);
      }
    } finally {
      _saving = null;
    }
  }

  @override
  void onClose() {
    for (final n in _lineNotifiers.values) {
      n.dispose();
    }
    _lineNotifiers.clear();
    for (final n in _productNotifiers.values) {
      n.dispose();
    }
    _productNotifiers.clear();
    for (final n in _offerNotifiers.values) {
      n.dispose();
    }
    _offerNotifiers.clear();
    super.onClose();
  }

  @override
  void resetForSignOut() {
    // Memory only (persist: false): the saved current_cart row stays and
    // is reloaded by the next sign-in (same store) or dropped (other store).
    _apply(Cart.empty, persist: false);
  }
}

/// What the cart holds of one product, for its tile (DEC-154): the base-unit
/// line (if any), all lines in base units, and whether any line is packaged.
class ProductInCart {
  const ProductInCart({
    required this.baseLine,
    required this.totalBase,
    required this.packaged,
  });

  /// Null when the cart holds the product only in packagings.
  final CartLine? baseLine;
  final Qty totalBase;
  final bool packaged;

  static ProductInCart? of(Cart cart, int productId) {
    CartLine? base;
    var packaged = false;
    var found = false;
    for (final line in cart.lines) {
      if (line.product.id != productId) continue;
      found = true;
      if (line.packaging == null) {
        base = line;
      } else {
        packaged = true;
      }
    }
    if (!found) return null;
    return ProductInCart(
      baseLine: base,
      totalBase: cart.baseQtyOf(productId),
      packaged: packaged,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProductInCart &&
      other.baseLine == baseLine &&
      other.totalBase == totalBase &&
      other.packaged == packaged;

  @override
  int get hashCode => Object.hash(baseLine, totalBase, packaged);
}
