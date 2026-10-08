import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../controllers/catalog_controller.dart';
import '../../products/models/product.dart';
import 'catalog_product_card.dart';

/// Scrolling product grid or list. Builds only the visible cards (lazy sliver
/// grid, stable `ValueKey(product.id)`); columns follow
/// `repeat(auto-fill, minmax(min, 1fr))`.
class ProductGrid extends StatefulWidget {
  const ProductGrid({super.key});

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  final ScrollController _scroll = ScrollController();

  /// Card widgets by product id. The same instance is returned while product
  /// and mode are unchanged, so the element tree skips rebuilding it.
  final Map<int, CatalogProductCard> _cards = <int, CatalogProductCard>{};
  bool _cardsForList = false;

  CatalogProductCard _card(Product product, bool list) {
    if (list != _cardsForList) {
      _cards.clear();
      _cardsForList = list;
    }
    final cached = _cards[product.id];
    if (cached != null && cached.product == product) return cached;
    return _cards[product.id] = CatalogProductCard(
      key: ValueKey<int>(product.id),
      product: product,
      list: list,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final c = context.colors;
    final catalog = Get.find<CatalogController>();
    return RawScrollbar(
      controller: _scroll,
      thumbColor: c.scrollThumb,
      thickness: AppSizes.scrollbarThickness,
      radius: const Radius.circular(AppRadii.full),
      child: LayoutBuilder(
        builder: (context, constraints) => Obx(() {
          final list = catalog.list.value;
          final items = catalog.filtered;
          final inner = constraints.maxWidth - 2 * AppSpacing.s2;
          final gap = m.productGridGap;
          final columns = list
              ? 1
              : math.max(
                  1,
                  ((inner + gap) / (m.productGridMinColumn + gap)).floor(),
                );
          return CustomScrollView(
            controller: _scroll,
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.s2),
                sliver: items.isEmpty
                    ? const SliverToBoxAdapter(child: _NoResults())
                    : SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: gap,
                          crossAxisSpacing: gap,
                          mainAxisExtent: list
                              ? m.productListCardHeight
                              : m.productCardHeight,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = items[index];
                            return _card(product, list);
                          },
                          childCount: items.length,
                          findChildIndexCallback: (key) {
                            final id = (key as ValueKey<int>).value;
                            final i = items.indexWhere((p) => p.id == id);
                            return i < 0 ? null : i;
                          },
                        ),
                      ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final text = context.text;
    final catalog = Get.find<CatalogController>();
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 65,
        horizontal: AppSpacing.s20,
      ),
      child: Column(
        children: <Widget>[
          Icon(AppIcons.search, size: AppSizes.noResultsIcon, color: c.muted),
          const SizedBox(height: AppSpacing.s13),
          Text(
            s.noResultsTitle(),
            style: text
                .of(
                  AppFontSize.s20,
                  weight: AppFontWeight.bold,
                  height: AppLineHeight.base,
                )
                .copyWith(color: c.muted),
          ),
          const SizedBox(height: AppSpacing.s13),
          Text(
            s.noResultsHint(),
            style: text
                .of(AppFontSize.s14, height: AppLineHeight.base)
                .copyWith(color: c.muted),
          ),
          const SizedBox(height: AppSpacing.s13),
          AppPressable(
            onTap: catalog.resetFilters,
            builder: (context, hovered) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
              child: Text(
                s.resetFilters(),
                style: text
                    .of(AppFontSize.s14, height: AppLineHeight.base)
                    .copyWith(color: c.blue),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
