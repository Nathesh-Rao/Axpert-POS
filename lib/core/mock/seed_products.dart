import '../../modules/products/models/product.dart';
import '../services/pricing/basis_points.dart';
import '../services/pricing/currency_registry.dart';
import '../services/pricing/money.dart';

/// The prototype's 20 products (`data.ts` `sampleProducts`), prices in rupees
/// converted to minor units.
abstract final class SeedProducts {
  // name, code, price (rupees), category, sub, image
  static const List<(String, String, int, String, String, int)> _rows = [
    ('Coca Cola 500ml', 'BDV001', 40, 'Beverages', 'Soft Drinks', 0),
    ('Pepsi 500ml', 'BDV002', 40, 'Beverages', 'Soft Drinks', 1),
    ('Sprite 500ml', 'BDV003', 40, 'Beverages', 'Soft Drinks', 2),
    ('Fanta 500ml', 'BDV004', 40, 'Beverages', 'Soft Drinks', 3),
    ('Kinley Water 1L', 'WTR001', 20, 'Beverages', 'Water', 4),
    ('Lays Classic 52g', 'CHP001', 20, 'Snacks', 'Chips', 5),
    ('Lays Masala 52g', 'CHP002', 20, 'Snacks', 'Chips', 6),
    ('Oreo Biscuit 120g', 'BSC001', 35, 'Snacks', 'Biscuits', 7),
    ('Dairy Milk 40g', 'CHC001', 40, 'Snacks', 'Confectionery', 8),
    ('KitKat 4 Finger', 'CHD002', 30, 'Snacks', 'Confectionery', 9),
    ('Maggi Noodles', 'NOD001', 14, 'Snacks', 'Noodles', 10),
    ('Closeup 150g', 'PER001', 85, 'Personal Care', 'Oral Care', 11),
    ('Real Mango Juice 1L', 'JUC001', 110, 'Beverages', 'Juices', -1),
    ('Tropicana Orange 1L', 'JUC002', 125, 'Beverages', 'Juices', -1),
    ('Paper Boat Aam 200ml', 'JUC003', 30, 'Beverages', 'Juices', -1),
    ('Dove Soap 100g', 'PER002', 65, 'Personal Care', 'Bath & Body', -1),
    ('Dettol Handwash 200ml', 'PER003', 99, 'Personal Care', 'Bath & Body', -1),
    ('Colgate Total 100g', 'PER004', 90, 'Personal Care', 'Oral Care', -1),
    ('Good Day Cookies 100g', 'BSC002', 25, 'Snacks', 'Biscuits', -1),
    ('Himalaya Shampoo 200ml', 'PER005', 155, 'Personal Care', 'Hair Care', -1),
  ];

  static const List<int> _gstPercent = [18, 12, 5];
  static const List<int> _favourites = [0, 5, 8];

  static List<Product> products() => <Product>[
    for (var i = 0; i < _rows.length; i++) _build(i),
  ];

  static Product _build(int index) {
    final row = _rows[index];
    return Product(
      id: index,
      name: row.$1,
      code: row.$2,
      barcode: index < 10
          ? '${8901234567890 + index}'
          : '${8901234567800 + index - 10}',
      price: Money(row.$3 * 100, CurrencyRegistry.inr),
      category: row.$4,
      sub: row.$5,
      stock: index == 14 ? 8 : 45 + index * 3,
      gst: Bp(_gstPercent[index % 3] * 100),
      image: row.$6,
      favourite: _favourites.contains(index),
    );
  }
}
