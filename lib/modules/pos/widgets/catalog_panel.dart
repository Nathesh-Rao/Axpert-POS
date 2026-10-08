import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/app_panel.dart';
import '../../../shared/widgets/product_image.dart';
import '../../products/controllers/products_controller.dart';
import '../controllers/cart_controller.dart';
import 'catalog_tools.dart';
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

/// `.empty-customer` row. Only its caption exists in S3; the customer chip,
/// sale toggle and add button arrive in S4.
class _EmptyCartHeader extends StatelessWidget {
  const _EmptyCartHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    final s = context.strings;
    final products = Get.find<ProductsController>();
    final style = context.text
        .fluid(9, height: AppLineHeight.base)
        .copyWith(color: c.muted);
    return Column(
      children: <Widget>[
        Container(
          height:
              AppSizes.emptyCustomerRowHeight +
              m.emptyCustomerPaddingBottom +
              AppSizes.borderWidth,
          padding: EdgeInsets.only(bottom: m.emptyCustomerPaddingBottom),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.border)),
          ),
          alignment: Alignment.centerRight,
          child: m.atMost1280
              ? null
              : Obx(
                  () => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        s.catalogCaptionTitle(),
                        style: style.copyWith(
                          letterSpacing: AppTracking.catalogCaption,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      Text(
                        s.catalogCaptionCount(products.products.length),
                        style: style,
                      ),
                    ],
                  ),
                ),
        ),
        SizedBox(height: m.emptyCustomerMarginBottom),
      ],
    );
  }
}
