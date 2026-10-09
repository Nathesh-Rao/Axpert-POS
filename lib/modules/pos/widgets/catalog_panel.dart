import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/widgets/app_panel.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../../../shared/widgets/product_image.dart';
import '../../products/controllers/products_controller.dart';
import '../controllers/cart_controller.dart';
import 'catalog_tools.dart';
import 'customer_select.dart';
import 'sale_toggle.dart';
import 'category_bar.dart';
import 'product_grid.dart';
import 'subcategory_bar.dart';

/// The catalog panel: header (empty-cart row), category chips, subcategory
/// chips, search and view toggle, and the product grid.
class CatalogPanel extends StatefulWidget {
  const CatalogPanel({super.key});

  @override
  State<CatalogPanel> createState() => _CatalogPanelState();
}

class _CatalogPanelState extends State<CatalogPanel> {
  static const int _precacheCount = 24;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    // First screen: decode the visible images before they scroll in.
    final products = Get.find<ProductsController>().products;
    var count = 0;
    for (final p in products) {
      if (!p.hasImage) continue;
      precacheImage(
        ResizeImage(
          AssetImage(ProductImage.assetPath(p.image)),
          width: AppSizes.productImageCacheWidth.toInt(),
        ),
        context,
        onError: (_, _) {},
      );
      if (++count >= _precacheCount) break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final cart = Get.find<CartController>();
    return AppPanel(
      padding: EdgeInsets.all(m.panelPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Obx(
            () => cart.active.value
                ? const SizedBox.shrink()
                : const _EmptyCartHeader(),
          ),
          const CategoryBar(),
          SizedBox(height: m.subcategoriesMarginTop),
          const SubcategoryBar(),
          SizedBox(height: m.catalogToolsMarginY),
          const CatalogTools(),
          SizedBox(height: m.catalogToolsMarginY),
          const Expanded(child: ProductGrid()),
        ],
      ),
    );
  }
}

/// `.empty-customer` row: customer chip, sale toggle, add button and the
/// catalog caption (hidden at width <= 1280).
class _EmptyCartHeader extends StatelessWidget {
  const _EmptyCartHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    final s = context.strings;
    final overlay = Get.find<OverlayController>();
    final products = Get.find<ProductsController>();
    final captionStyle = context.text
        .fluid(
          m.atMost1280 ? AppFontSize.s9.px : AppFontSize.s10.px,
          height: AppLineHeight.base,
        )
        .copyWith(color: c.muted);
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(bottom: m.emptyCustomerPaddingBottom),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.border)),
          ),
          // `margin-left:auto` on the caption: the chip, the sale toggle and the
          // add button keep their natural width at the left (the chip only
          // shrinks when it must) and the caption sits at the right edge.
          child: Row(
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s7,
                            vertical: AppSpacing.s5,
                          ),
                          decoration: BoxDecoration(
                            color: c.secondary,
                            borderRadius: BorderRadius.circular(AppRadii.r7),
                            border: Border.all(
                              color: c.border,
                              width: AppSizes.borderWidth,
                            ),
                          ),
                          // Below the supported widths the chip scales down instead of
                          // overflowing.
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  AppIcons.userRound,
                                  size: AppCheckoutSizes.chipIcon,
                                  color: c.fieldIcon,
                                ),
                                const SizedBox(width: AppSpacing.s5),
                                SizedBox(
                                  width: m.customerSelectWidth,
                                  child: CustomerSelect(
                                    style: context.text.fluid(
                                      m.customerSelectFont,
                                    ),
                                    semanticLabel: s.customerLabel(),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s5),
                                AppPressable(
                                  tooltip: s.customerSearchTooltip(),
                                  borderRadius: AppRadii.r6,
                                  onTap: () => overlay.open('customers'),
                                  builder: (context, hovered) => Container(
                                    padding: const EdgeInsets.only(
                                      left: AppSpacing.s5,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(color: c.border),
                                      ),
                                    ),
                                    child: Icon(
                                      AppIcons.search,
                                      size: AppCheckoutSizes.chipSearchIcon,
                                      color: c.fieldIcon,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s6),
                      const SaleToggle(),
                      const SizedBox(width: AppSpacing.s6),
                      AppPressable(
                        tooltip: s.addCustomerTooltip(),
                        borderRadius: AppRadii.r6,
                        onTap: () => overlay.open('addCustomer'),
                        builder: (context, hovered) => Padding(
                          padding: const EdgeInsets.all(AppSpacing.s6),
                          child: Icon(
                            AppIcons.plus,
                            size: AppCheckoutSizes.headerAddIcon,
                            color: c.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!m.atMost1280) ...<Widget>[
                Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        s.catalogCaptionTitle(),
                        style: captionStyle.copyWith(
                          letterSpacing: AppTracking.catalogCaption,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      Text(
                        s.catalogCaptionCount(products.products.length),
                        style: captionStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: m.emptyCustomerMarginBottom),
      ],
    );
  }
}
