import 'package:flutter/foundation.dart';

import '../../modules/products/models/product.dart';
import '../services/pricing/basis_points.dart';
import '../services/pricing/currency_registry.dart';
import '../services/pricing/money.dart';

/// Debug-only large catalog for performance work. Enabled with
/// `--dart-define=LARGE_DATASET=true` in debug builds; off by default.
abstract final class LargeDataset {
  static const bool _flag = bool.fromEnvironment('LARGE_DATASET');

  static bool get enabled => kDebugMode && _flag;

  static const List<(String, List<String>)> _categories = [
    ('Beverages', ['Soft Drinks', 'Juices', 'Water']),
    ('Snacks', ['Chips', 'Biscuits', 'Confectionery', 'Noodles']),
    ('Personal Care', ['Oral Care', 'Bath & Body', 'Hair Care']),
  ];

  /// Deterministic products; ids 0..count-1, no images for ids >= 12 so the
  /// grid also exercises the placeholder path.
  static List<Product> products([int count = 10000]) => <Product>[
    for (var i = 0; i < count; i++) _build(i),
  ];

  static Product _build(int i) {
    final cat = _categories[i % _categories.length];
    final sub = cat.$2[(i ~/ 3) % cat.$2.length];
    return Product(
      id: i,
      name: 'Item ${i.toString().padLeft(5, '0')} ${cat.$1.split(' ').first}',
      code: 'LD${i.toString().padLeft(5, '0')}',
      barcode: '${8900000000000 + i}',
      price: Money((10 + (i * 7) % 490) * 100, CurrencyRegistry.inr),
      category: cat.$1,
      sub: sub,
      stock: 5 + (i * 13) % 200,
      gst: Bp([18, 12, 5][i % 3] * 100),
      image: i < 12 ? i : -1,
      favourite: i % 17 == 0,
    );
  }
}
