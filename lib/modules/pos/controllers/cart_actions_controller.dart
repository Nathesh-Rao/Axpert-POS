import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/services/beep_service.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../shared/controllers/search_field_controller.dart';
import '../../../shared/controllers/toast_controller.dart';
import '../../../features/products/presentation/controllers/products_controller.dart';
import '../../../features/products/domain/entities/product.dart';
import '../../../core/services/packaging/packaging_ref.dart';
import '../../../core/services/pricing/money.dart';
import '../models/cart_line.dart';
import '../models/line_key.dart';
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

  /// Returns false when the add was blocked by stock. [packaging] and its
  /// package [price] add one package instead of one base unit (DEC-154); the
  /// stock check counts base units across all lines of the product.
  bool add(Product product, {PackagingRef? packaging, Money? price}) {
    final key = LineKey(product.id, packaging?.id);
    final factor = packaging?.quantityBaseMilli ?? 1000;
    final used = cart.cart.value.baseQtyOf(product.id).milli;
    if (used + factor > product.stockQty.milli) {
      toasts.show(
        _s.toastStockAvailable(product.stock),
        kind: ToastKind.warning,
      );
      return false;
    }
    cart.addItem(product, packaging: packaging, price: price);
    selection.flash(key);
    selection.select(key);
    toasts.show(
      packaging == null
          ? _s.toastProductAdded(product.name)
          : _s.toastProductAddedUnit(product.name, packaging.unitName),
    );
    beep.play();
    search.text.clear();
    search.refocus();
    return true;
  }

  void remove(CartLine line) {
    cart.removeLine(line.key);
    toasts.show(
      _s.toastProductRemoved(line.product.name),
      kind: ToastKind.info,
      onUndo: () => cart.restoreLine(line),
    );
    search.refocus();
  }

  /// [qty] is the wanted quantity of the line; the live product stock (base
  /// units, summed across the lines of the product) is the limit.
  void changeQty(CartLine line, Qty qty) {
    final stock = products.byId(line.product.id)?.stockQty ?? Qty.zero;
    final others = cart.cart.value
        .baseQtyOf(line.product.id, except: line.key)
        .milli;
    final factor = line.packaging?.quantityBaseMilli ?? 1000;
    final wantedBase = qty.milli * factor ~/ 1000;
    if (others + wantedBase > stock.milli) {
      final left = (stock.milli - others) * 1000 ~/ factor;
      toasts.show(
        _s.toastStockOnly((left < 0 ? 0 : left) ~/ 1000),
        kind: ToastKind.warning,
      );
      return;
    }
    if (qty <= Qty.zero) {
      remove(line);
    } else {
      cart.setQty(line.key, qty);
    }
  }

  void clear() {
    cart.clear();
    search.refocus();
  }

  /// Delete key: removes the selected line, if any.
  void removeSelected() {
    final key = selection.selected.value;
    if (key == null) return;
    final line = cart.lineOf(key);
    if (line != null) remove(line);
  }
}
