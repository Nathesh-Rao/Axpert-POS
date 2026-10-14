import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_density_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../controllers/catalog_controller.dart';
import '../../../features/products/domain/entities/product.dart';
import '../controllers/cart_controller.dart';
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
  bool _cardsCompact = false;

  CatalogProductCard _card(Product product, bool list, bool compact) {
    if (list != _cardsForList || compact != _cardsCompact) {
      _cards.clear();
      _cardsForList = list;
      _cardsCompact = compact;
    }
    final cached = _cards[product.id];
    if (cached != null && cached.product == product) return cached;
    return _cards[product.id] = CatalogProductCard(
      key: ValueKey<int>(product.id),
      product: product,
      list: list,
      compact: compact,
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
          final wantList = catalog.list.value;
          final items = catalog.filtered;
          final inner = constraints.maxWidth - 2 * AppSpacing.s2;
          final gap = m.productGridGap;
          // The narrow Products panel (DEC-141): when two regular cards do not
          // fit, a compact tile in one or two columns replaces grid and list.
          final compact = inner < 2 * m.productGridMinColumn + gap;
          final list = wantList && !compact;
          final fixed = m.catalogFixedColumns(
            cartOpen: Get.find<CartController>().active.value,
            list: list,
          );
          final columns = compact
              ? ((inner + gap) / (AppDensitySizes.compactColumnMin + gap))
                    .floor()
                    .clamp(1, AppDensitySizes.compactMaxColumns)
              : list
              ? 1
              : fixed ??
                    math.max(
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
                          mainAxisExtent: compact
                              ? m.productCompactCardHeight
                              : list
                              ? m.productListCardHeight
                              : m.productCardHeight,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = items[index];
                            return _card(product, list, compact);
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
