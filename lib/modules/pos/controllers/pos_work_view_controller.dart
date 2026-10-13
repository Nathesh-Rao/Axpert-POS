import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../shared/controllers/search_field_controller.dart';
import 'cart_controller.dart';

/// The two views of the desktop POS work area (DEC-139).
enum PosWorkView { catalog, cart }

/// Which view the desktop work area shows. Nothing is stored: with an empty
/// cart it is always the catalog, with items it is the user's choice (the cart
/// until they switch). Adding through the search box, a scan or a recall shows
/// the cart; clicking a catalog tile keeps the catalog so several products
/// can be picked in a row.
class PosWorkViewController extends GetxController {
  PosWorkViewController(this._cart, this._search);

  final CartController _cart;
  final SearchFieldController _search;

  final Rxn<PosWorkView> _chosen = Rxn<PosWorkView>();

  /// Counts tile adds; the tab flashes once per change.
  final RxInt pulse = 0.obs;

  /// Focus target of the cart list (set when the cart view is shown by hand).
  final FocusNode cartFocus = FocusNode(debugLabel: 'cart-list');

  @override
  void onInit() {
    super.onInit();
    // An empty cart always goes back to the catalog; the choice is forgotten.
    ever<bool>(_cart.active, (active) {
      if (!active) _chosen.value = null;
    });
  }

  @override
  void onClose() {
    cartFocus.dispose();
    super.onClose();
  }

  /// The view to show now (reactive through the cart and the choice).
  PosWorkView get view => !_cart.active.value
      ? PosWorkView.catalog
      : (_chosen.value ?? PosWorkView.cart);

  bool get inCatalog => view == PosWorkView.catalog;

  /// False while the cart is empty: there is nothing to switch to.
  bool get canSwitch => _cart.active.value;

  /// Lines in the cart (the tab count).
  int get count => _cart.totals.value.items;

  /// Adding through the search box, a scan or a recall: the cart view. The
  /// search keeps the focus (the next scan goes into it).
  void showCart() => _chosen.value = PosWorkView.cart;

  /// The tab, Ctrl/Cmd+B and Escape: switch by hand and move the focus (the
  /// search box in the catalog, the cart list in the cart).
  void toggle() {
    if (!canSwitch) return;
    _chosen.value = inCatalog ? PosWorkView.cart : PosWorkView.catalog;
    _focusAfterSwitch();
  }

  /// Escape with nothing else open: the catalog with items returns to the cart.
  void back() {
    if (!canSwitch || !inCatalog) return;
    _chosen.value = PosWorkView.cart;
    _focusAfterSwitch();
  }

  /// A tile click: [add] runs. When it worked on an empty cart the cart view
  /// shows (DEC-140); otherwise the catalog stays and the tab pulses.
  void addFromCatalog(bool Function() add) {
    final wasEmpty = !_cart.active.value;
    if (!add()) return;
    if (wasEmpty && _cart.active.value) {
      showCart();
      return;
    }
    _chosen.value = PosWorkView.catalog;
    pulse.value++;
  }

  void _focusAfterSwitch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (inCatalog) {
        _search.refocus();
      } else if (cartFocus.context != null) {
        cartFocus.requestFocus();
      }
    });
  }
}
