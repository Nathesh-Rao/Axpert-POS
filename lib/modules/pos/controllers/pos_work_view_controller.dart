import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../shared/controllers/search_field_controller.dart';
import '../../shell/controllers/settings_controller.dart';
import '../../shell/models/app_settings.dart';
import '../models/pos_panel_layout.dart';
import 'cart_controller.dart';

/// Layout of the desktop POS work area (DEC-141): Products | Cart | Billing,
/// each with size states; the cart takes what is left.
///
/// Three layers, so the user's choice survives every automatic change:
/// - `chosen`: what the user picked (Products step, Billing open). Stored per
///   device through [SettingsController] on every explicit action.
/// - `effective`: what is drawn. An empty cart shows the catalog layout
///   (Products 75, Billing as chosen); a window too small for the choice falls
///   back to the nearest state that fits (Billing closes first, then Products
///   shrinks). Neither of these changes `chosen`.
/// - `lastCartProducts`: the last Products step with the cart visible; the
///   first add to an empty cart, a search or scan add at Products 75, a recall
///   and Escape go back to it.
class PosWorkViewController extends GetxController {
  PosWorkViewController(this._cart, this._search, this._settings);

  final CartController _cart;
  final SearchFieldController _search;
  final SettingsController _settings;

  final Rx<ProductsStep> _products = ProductsStep.off.obs;
  final RxBool _billing = true.obs;
  ProductsStep _lastCartProducts = ProductsStep.off;

  /// True once the user acted: the stored choice is then no longer read back.
  bool _userChose = false;

  /// Window numbers of the desktop layout, set by the layout while it builds
  /// (a plain field, not an observable) and cleared when it leaves. Null on
  /// touch and on other pages: the layout actions then do nothing.
  PanelGeometry? geometry;

  /// Counts tile adds at Products 75; the edge control flashes once per change.
  final RxInt pulse = 0.obs;

  /// Focus target of the cart list (set when the cart is shown by hand).
  final FocusNode cartFocus = FocusNode(debugLabel: 'cart-list');

  @override
  void onInit() {
    super.onInit();
    _adopt(_settings.settings.value);
    // The settings load after this controller exists: take the stored choice
    // once, unless the user already acted.
    ever(_settings.settings, (s) {
      if (!_userChose) _adopt(s);
    });
    // An empty cart returns to the catalog layout; the next first add goes
    // back to the last layout with the cart visible.
    ever<bool>(_cart.active, (active) {
      if (!active) _products.value = _lastCartProducts;
    });
  }

  @override
  void onClose() {
    cartFocus.dispose();
    super.onClose();
  }

  void _adopt(AppSettings settings) {
    final step = ProductsStep.fromPercent(settings.posProductsStep);
    _billing.value = settings.posBillingOpen;
    if (step != ProductsStep.wide) _lastCartProducts = step;
    // Products 75 with an empty cart is the empty-cart layout, not a choice
    // to come back to.
    _products.value = step == ProductsStep.wide && !_cart.active.value
        ? _lastCartProducts
        : step;
  }

  // --- state ---------------------------------------------------------------

  /// What the user picked.
  PanelLayout get chosen =>
      PanelLayout(_products.value, billing: _billing.value);

  /// What is drawn now (reactive through the cart, the choice and, once the
  /// layout built, the window).
  PanelLayout get effective {
    var layout = chosen;
    if (!_cart.active.value) {
      layout = layout.withProducts(ProductsStep.wide);
    }
    return geometry?.fit(layout) ?? layout;
  }

  /// Products 75 (the cart hidden or a quarter wide).
  bool get inCatalog => effective.catalogDominant;

  bool get billingOpen => effective.billing;

  /// False while the cart is empty: the layout is the catalog then.
  bool get canSwitch => _cart.active.value;

  /// Lines in the cart (the edge control's count).
  int get count => _cart.totals.value.items;

  // --- Products ------------------------------------------------------------

  static const List<ProductsStep> _order = ProductsStep.values;

  /// The nearest step in [direction] (+1 wider, -1 narrower, wrapping when
  /// [wrap]) that changes what is drawn; null when none does.
  ProductsStep? _next(int direction, {bool wrap = false}) {
    if (!canSwitch || geometry == null) return null;
    final shown = effective;
    final from = _order.indexOf(_products.value);
    for (var i = 1; i < _order.length; i++) {
      final index = from + direction * i;
      if (!wrap && (index < 0 || index >= _order.length)) break;
      final step = _order[index % _order.length];
      if (geometry!.fit(chosen.withProducts(step)) != shown) return step;
    }
    return null;
  }

  bool get canWider => _next(1) != null;
  bool get canNarrower => _next(-1) != null;

  /// Ctrl/Cmd+B: 0 -> 25 -> 75 -> 0.
  void cycleProducts() {
    final step = _next(1, wrap: true);
    if (step != null) _setProducts(step);
  }

  /// A click on the edge control's body: with the catalog layout up and items
  /// in the cart ("Cart (n)") it shows the cart, otherwise it cycles.
  void edgeTap() {
    if (effective.catalogDominant && _cart.active.value) {
      back();
    } else {
      cycleProducts();
    }
  }

  /// The chevron buttons.
  void wider() {
    final step = _next(1);
    if (step != null) _setProducts(step);
  }

  void narrower() {
    final step = _next(-1);
    if (step != null) _setProducts(step);
  }

  /// The shortcut action (`ShortcutAction.switchWorkView`).
  void toggle() => cycleProducts();

  /// Escape with nothing else open: the catalog layout with items returns to
  /// the last layout with the cart visible.
  void back() {
    if (geometry == null || !_cart.active.value || !effective.catalogDominant) {
      return;
    }
    _setProducts(_lastCartProducts);
  }

  void _setProducts(ProductsStep step) {
    _products.value = step;
    if (step != ProductsStep.wide) _lastCartProducts = step;
    _persist();
    _focusAfterChange();
  }

  /// A search, scan or recall add: show the cart layout when the catalog
  /// layout is up. Not stored (the choice is not changed by the app).
  void showCart() {
    if (_cart.active.value && _products.value == ProductsStep.wide) {
      _products.value = _lastCartProducts;
    }
  }

  /// A tile click: [add] runs. The layout stays; with the catalog layout up
  /// the edge control flashes the new count. The first add to an empty cart
  /// shows the last cart layout through `effective`.
  void addFromCatalog(bool Function() add) {
    final wasEmpty = !_cart.active.value;
    if (!add()) return;
    if (!wasEmpty && effective.catalogDominant) pulse.value++;
  }

  // --- Billing -------------------------------------------------------------

  /// Ctrl/Cmd+. and the collapse button.
  void toggleBilling() {
    if (geometry == null) return;
    effective.billing ? closeBilling() : openBilling();
  }

  void closeBilling() {
    if (geometry == null) return;
    _billing.value = false;
    _persist();
    _focusAfterChange();
  }

  /// Opens Billing (the footer chip, the shortcut). When the window cannot
  /// hold it next to the chosen Products step, Products shrinks until it can.
  /// [refocus] is false for the payment shortcuts, which focus the payment
  /// field themselves.
  void openBilling({bool refocus = true}) {
    if (geometry == null) return;
    _billing.value = true;
    while (!effective.billing && _products.value != ProductsStep.off) {
      _products.value = _products.value == ProductsStep.wide
          ? ProductsStep.narrow
          : ProductsStep.off;
    }
    if (_products.value != ProductsStep.wide) {
      _lastCartProducts = _products.value;
    }
    _persist();
    if (refocus) _focusAfterChange();
  }

  /// F2 and F3: the payment panel lives in Billing, so open it first.
  void openBillingForPayment() {
    if (_cart.active.value && !effective.billing) {
      openBilling(refocus: false);
    }
  }

  // --- helpers -------------------------------------------------------------

  void _persist() {
    _userChose = true;
    unawaited(
      _settings.setPosLayout(
        productsStep: _products.value.percent,
        billing: _billing.value,
      ),
    );
  }

  /// After a change by hand: the search box with the catalog layout, the cart
  /// list otherwise.
  void _focusAfterChange() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (effective.catalogDominant || !_cart.active.value) {
        _search.refocus();
      } else if (cartFocus.context != null) {
        cartFocus.requestFocus();
      }
    });
  }
}
