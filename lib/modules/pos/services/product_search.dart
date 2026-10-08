import '../../products/models/product.dart';

/// The top-bar search rules of the prototype as plain Dart.
abstract final class ProductSearch {
  /// The dropdown shows at most this many products.
  static const int limit = 6;

  static final RegExp _digits = RegExp(r'^\d+$');

  /// `/^\d+$/`: an all-digit text is a barcode, not a name search.
  static bool isDigitsOnly(String text) => _digits.hasMatch(text);

  /// `search && !/^\d+$/.test(search) ? products.filter(name+code includes
  /// search).slice(0, 6) : []`, in list order. [keyOf] gives the lowercase
  /// `"name code"` text of a product (precomputed by the products controller).
  /// The scan stops at the sixth match, so a common query touches few
  /// products; only a query without matches walks the whole list.
  static List<Product> matches(
    Iterable<Product> products,
    String Function(Product) keyOf,
    String query, {
    int max = limit,
  }) {
    if (query.isEmpty || isDigitsOnly(query)) return const <Product>[];
    final needle = query.toLowerCase();
    final found = <Product>[];
    for (final product in products) {
      if (keyOf(product).contains(needle)) {
        found.add(product);
        if (found.length >= max) break;
      }
    }
    return found;
  }
}
