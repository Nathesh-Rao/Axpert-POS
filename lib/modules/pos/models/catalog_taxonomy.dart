import '../../../core/theme/tokens/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Catalog categories of the prototype's chip row, in order.
enum CatalogCategory {
  allItems(null, AppIcons.star),
  favourites(null, AppIcons.star),
  beverages('Beverages', AppIcons.cupSoda),
  snacks('Snacks', AppIcons.cookie),
  personalCare('Personal Care', AppIcons.bottleWine);

  const CatalogCategory(this.dataName, this.icon);

  /// Value of `Product.category`; null for the two virtual categories.
  final String? dataName;
  final IconData icon;

  /// Subcategory chips (without the leading "All"), as the prototype lists
  /// them. "All Items" and "Favourites" omit Oral Care, Bath & Body, Hair Care
  /// and Noodles (KG-019).
  List<String> get subcategories => switch (this) {
    CatalogCategory.personalCare => const <String>[
      'Oral Care',
      'Bath & Body',
      'Hair Care',
    ],
    CatalogCategory.snacks => const <String>[
      'Chips',
      'Biscuits',
      'Confectionery',
      'Noodles',
    ],
    CatalogCategory.beverages => const <String>[
      'Soft Drinks',
      'Juices',
      'Water',
    ],
    _ => const <String>[
      'Soft Drinks',
      'Juices',
      'Water',
      'Chips',
      'Biscuits',
      'Confectionery',
    ],
  };
}
