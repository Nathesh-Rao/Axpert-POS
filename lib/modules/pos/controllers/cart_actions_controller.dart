import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/beep_service.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../shared/controllers/search_field_controller.dart';
import '../../../shared/controllers/toast_controller.dart';
import '../../products/controllers/products_controller.dart';
import '../../products/models/product.dart';
import '../models/cart_line.dart';
import 'cart_controller.dart';
import 'cart_selection_controller.dart';

/// The prototype's `add`, `remove` and `changeQty` flows: cart rule plus the
/// side effects (toast, beep, highlight, select, clear and refocus search).
class CartActionsController extends GetxController {
  CartActionsController({
    required this.cart,
    required this.products,
    required this.selection,
    required this.toasts,
    required this.search,
    required this.beep,
  });

  final CartController cart;
  final ProductsController products;
  final CartSelectionController selection;
  final ToastController toasts;
  final SearchFieldController search;
  final BeepService beep;

  AppStrings get _s => AppStrings.current;

  /// Returns false when the add was blocked by stock.
  bool add(Product product) {
    final current = cart.lineOf(product.id)?.qty ?? Qty.zero;
    if (current + Qty.units(1) > product.stockQty) {
      toasts.show(
        _s.toastStockAvailable(product.stock),
        kind: ToastKind.warning,
      );
      return false;
    }
    cart.addItem(product);
    selection.flash(product.id);
    selection.select(product.id);
    toasts.show(_s.toastProductAdded(product.name));
    beep.play();
    search.text.clear();
    search.refocus();
    return true;
  }

  void remove(CartLine line) {
    cart.removeLine(line.product.id);
    toasts.show(
      _s.toastProductRemoved(line.product.name),
      kind: ToastKind.info,
      onUndo: () => cart.restoreLine(line),
    );
    search.refocus();
  }

  /// [qty] is the wanted quantity; the live product stock is the limit.
  void changeQty(CartLine line, Qty qty) {
    final stock = products.byId(line.product.id)?.stockQty ?? Qty.zero;
    if (qty > stock) {
      toasts.show(
        _s.toastStockOnly(stock.milli ~/ 1000),
        kind: ToastKind.warning,
      );
      return;
    }
    if (qty <= Qty.zero) {
      remove(line);
    } else {
      cart.setQty(line.product.id, qty);
    }
  }

  void clear() {
    cart.clear();
    search.refocus();
  }

  /// Delete key: removes the selected line, if any.
  void removeSelected() {
    final id = selection.selected.value;
    if (id == null) return;
    final line = cart.lineOf(id);
    if (line != null) remove(line);
  }
}
