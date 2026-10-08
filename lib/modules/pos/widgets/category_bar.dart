import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_colors.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_motion.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../../../shared/widgets/star_icon.dart';
import '../controllers/catalog_controller.dart';
import '../models/catalog_taxonomy.dart';

/// Category chips with the "next" arrow that scrolls the row by 160 px.
class CategoryBar extends StatefulWidget {
  const CategoryBar({super.key});

  @override
  State<CategoryBar> createState() => _CategoryBarState();
}

class _CategoryBarState extends State<CategoryBar> {
  static const double _scrollStep = 160;

  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _next() {
    if (!_scroll.hasClients) return;
    final target = (_scroll.offset + _scrollStep).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: AppMotion.slideInMs),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    final s = context.strings;
    final catalog = Get.find<CatalogController>();
    final padding = EdgeInsets.symmetric(
      horizontal: m.categoryPadX,
      vertical: m.categoryPadY,
    );
    return SizedBox(
      height: m.categoryChipHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Obx(() {
              final selected = catalog.category.value;
              return SingleChildScrollView(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: <Widget>[
                    for (final category in CatalogCategory.values) ...<Widget>[
                      if (category != CatalogCategory.values.first)
                        const SizedBox(width: AppSpacing.s6),
                      AppChip(
                        key: ValueKey<CatalogCategory>(category),
                        label: _label(s, category),
                        selected: category == selected,
                        onTap: () => catalog.selectCategory(category),
                        padding: padding,
                        fontSize: m.catalogFont,
                        selectedForeground: c.white,
                        selectedGradient: <Color>[
                          c.categorySelectedTop,
                          c.categorySelectedBottom,
                        ],
                        leading: (fg) =>
                            _icon(c, category, category == selected, fg),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
          const SizedBox(width: AppSpacing.s6),
          _NextButton(onTap: _next),
        ],
      ),
    );
  }

  static String _label(AppStrings s, CatalogCategory category) =>
      switch (category) {
        CatalogCategory.allItems => s.categoryAllItems(),
        CatalogCategory.favourites => s.categoryFavourites(),
        _ => category.dataName!,
      };

  Widget _icon(
    AppColors c,
    CatalogCategory category,
    bool selected,
    Color foreground,
  ) {
    if (category == CatalogCategory.allItems) {
      return StarIcon(size: AppSizes.categoryIcon, color: foreground);
    }
    if (category == CatalogCategory.favourites) {
      return StarIcon(
        size: AppSizes.categoryIcon,
        color: selected ? foreground : c.categoryStar,
        fill: selected ? null : c.categoryStar,
      );
    }
    final color = switch (category) {
      CatalogCategory.beverages => c.categoryIcon3,
      CatalogCategory.snacks => c.categoryIcon4,
      _ => c.categoryIcon5,
    };
    return Icon(
      category.icon,
      size: AppSizes.categoryIcon,
      color: selected ? foreground : color,
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPressable(
      tooltip: context.strings.moreCategoriesTooltip(),
      onTap: onTap,
      borderRadius: AppRadii.r8,
      builder: (context, hovered) => Container(
        constraints: const BoxConstraints(minWidth: AppSizes.chipNextMinWidth),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(AppRadii.r8),
        ),
        child: Icon(
          AppIcons.chevronRight,
          size: AppSizes.chipNextIcon,
          color: c.text,
        ),
      ),
    );
  }
}
