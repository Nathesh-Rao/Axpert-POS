import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/utils/qty_formatter.dart';
import '../../../shared/controllers/search_field_controller.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/product_image.dart';
import '../../../features/offers/domain/entities/offer.dart';
import '../../../features/offers/presentation/controllers/offers_controller.dart';
import '../../../features/products/presentation/controllers/products_controller.dart';
import '../../../features/products/domain/entities/product.dart';
import '../controllers/cart_actions_controller.dart';
import '../controllers/pos_work_view_controller.dart';
import '../controllers/cart_controller.dart';
import 'units/unit_chips.dart';

/// A catalog card wired to the cart. It listens only to its own cart line; the
/// grid reuses the same widget instance while product and mode are unchanged,
/// so Flutter does not rebuild it when the grid rebuilds.
class CatalogProductCard extends StatelessWidget {
  const CatalogProductCard({
    required this.product,
    required this.list,
    this.compact = false,
    super.key,
  });

  final Product product;
  final bool list;

  /// The narrow Products panel's tile (DEC-141).
  final bool compact;

  /// Counts builds of the inner card (performance tests).
  static int builds = 0;

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final actions = Get.find<CartActionsController>();
    final offers = Get.find<OffersController>();
    return ValueListenableBuilder<ProductInCart?>(
      valueListenable: cart.productListenable(product.id),
      builder: (context, inCart, _) {
        builds++;
        // Reads `revision` so the badge follows a reload of the offers.
        return Obx(() {
          offers.revision.value;
          final tile = offers.tileOffer(product);
          return _card(context, inCart, actions, tile);
        });
      },
    );
  }

  Widget _card(
    BuildContext context,
    ProductInCart? inCart,
    CartActionsController actions,
    TileOffer? tile,
  ) {
    return ProductCard(
      name: product.name,
      code: product.code,
      price: MoneyFormatter.format(tile?.salePrice ?? product.price),
      strikePrice: tile?.salePrice == null
          ? null
          : MoneyFormatter.format(product.price),
      offerLabel: tile?.label,
      offerStyle: switch (tile?.kind) {
        OfferKind.discount => ProductOfferStyle.discount,
        OfferKind.promotion => ProductOfferStyle.promotion,
        OfferKind.giftTier => ProductOfferStyle.gift,
        null => null,
      },
      image: ProductImage(
        image: product.image,
        name: product.name,
        beverage: product.category == 'Beverages',
      ),
      favourite: product.favourite,
      list: list,
      compact: compact,
      packs: TilePackChip(product: product),
      // A product held only in packagings shows its total base units.
      qtyBadge: inCart == null
          ? null
          : context.strings.qtyBadge(
              QtyFormatter.compact(
                inCart.packaged ? inCart.totalBase : inCart.baseLine!.qty,
              ),
            ),
      onAdd: () => Get.find<PosWorkViewController>().addFromCatalog(
        () => actions.add(product),
      ),
      onRemoveOne: inCart?.baseLine == null
          ? null
          : () => actions.changeQty(
              inCart!.baseLine!,
              inCart.baseLine!.qty - Qty.units(1),
            ),
      onToggleFavourite: () {
        Get.find<ProductsController>().toggleFavourite(product.id);
        Get.find<SearchFieldController>().refocus();
      },
    );
  }
}
