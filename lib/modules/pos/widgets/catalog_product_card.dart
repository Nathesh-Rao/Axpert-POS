import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/qty_formatter.dart';
import '../../../shared/controllers/search_field_controller.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/product_image.dart';
import '../../products/controllers/products_controller.dart';
import '../../products/models/product.dart';
import '../controllers/cart_actions_controller.dart';
import '../controllers/cart_controller.dart';
import '../models/cart_line.dart';

/// A catalog card wired to the cart. It listens only to its own cart line; the
/// grid reuses the same widget instance while product and mode are unchanged,
/// so Flutter does not rebuild it when the grid rebuilds.
class CatalogProductCard extends StatelessWidget {
  const CatalogProductCard({
    required this.product,
    required this.list,
    super.key,
  });

  final Product product;
  final bool list;

  /// Counts builds of the inner card (performance tests).
  static int builds = 0;

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final actions = Get.find<CartActionsController>();
    return ValueListenableBuilder<CartLine?>(
      valueListenable: cart.lineListenable(product.id),
      builder: (context, line, _) {
        builds++;
        return ProductCard(
          name: product.name,
          code: product.code,
          price: MoneyFormatter.format(product.price),
          image: ProductImage(
            image: product.image,
            name: product.name,
            beverage: product.category == 'Beverages',
          ),
          favourite: product.favourite,
          list: list,
          qtyBadge: line == null
              ? null
              : context.strings.qtyBadge(QtyFormatter.compact(line.qty)),
          onAdd: () => actions.add(product),
          onRemoveOne: line == null
              ? null
              : () => actions.changeQty(line, line.qty - Qty.units(1)),
          onToggleFavourite: () {
            Get.find<ProductsController>().toggleFavourite(product.id);
            Get.find<SearchFieldController>().refocus();
          },
        );
      },
    );
  }
}
