import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../features/products/domain/entities/product.dart';
import '../../../features/products/presentation/controllers/products_controller.dart';
import '../../../shared/controllers/search_field_controller.dart';
import '../../../shared/controllers/toast_controller.dart';
import '../models/cart_line.dart';
import '../models/unit_option.dart';
import 'cart_actions_controller.dart';
import 'cart_controller.dart';
import 'cart_selection_controller.dart';
import 'packaging_catalog_controller.dart';

/// Choosing the unit a product is sold in (DEC-154): adding a packaging from
/// a tile, switching the unit of a cart row, and the shortcut that cycles the
/// unit of the selected row.
class UnitSwitchController extends GetxController {
  UnitSwitchController({
    required this.catalog,
    required this.cart,
    required this.actions,
    required this.selection,
    required this.products,
    required this.toasts,
    required this.search,
  });

  final PackagingCatalogController catalog;
  final CartController cart;
  final CartActionsController actions;
  final CartSelectionController selection;
  final ProductsController products;
  final ToastController toasts;
  final SearchFieldController search;

  AppStrings get _s => AppStrings.current;

  /// Adds one unit of [option] of [product] (tile popover).
  bool add(Product product, UnitOption option) => actions.add(
    product,
    packaging: option.packaging,
    price: option.isBase ? null : option.price,
  );

  /// Sells [line] in [option] instead (cart row chip). Blocked, with the
  /// stock toast, when the base stock does not allow the new unit.
  void switchLine(CartLine line, UnitOption option) {
    if (line.packaging?.id == option.packagingId) {
      search.refocus();
      return;
    }
    final before = cart.cart.value;
    cart.changeUnit(line.key, option.packaging, option.price);
    if (identical(cart.cart.value, before)) {
      toasts.show(
        _s.toastStockAvailable(
          (products.byId(line.product.id) ?? line.product).stock,
        ),
        kind: ToastKind.warning,
      );
    } else {
      final key = line.product.id;
      selection.select(
        cart.cart.value.lines
            .firstWhere(
              (l) =>
                  l.product.id == key && l.packaging?.id == option.packagingId,
            )
            .key,
      );
    }
    search.refocus();
  }

  /// Ctrl/Cmd+Shift+U: the next unit of the selected cart row (wraps).
  void cycleSelected() {
    final key = selection.selected.value;
    final line = key == null ? null : cart.lineOf(key);
    if (line == null) return;
    final live = products.byId(line.product.id) ?? line.product;
    final options = catalog.optionsFor(live);
    if (options.length < 2) return;
    final at = options.indexWhere((o) => o.packagingId == line.packaging?.id);

    switchLine(line, options[(at + 1) % options.length]);
  }
}
