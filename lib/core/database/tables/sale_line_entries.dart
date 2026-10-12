import 'package:drift/drift.dart';

import 'product_entries.dart';
import 'sale_entries.dart';

/// Lines of a sale with the full product snapshot (provisional, local-only,
/// DEC-129). One line per product id (the cart merges equal products), so the
/// prototype's `returned` map keys map to lines.
@DataClassName('SaleLineEntry')
class SaleLineEntries extends Table {
  @override
  String get tableName => 'sale_lines';

  TextColumn get id => text()();

  TextColumn get saleId => text().references(SaleEntries, #id)();

  IntColumn get lineNo => integer()();

  /// Resolved link to `products.id`; null until the row is known.
  TextColumn get productId =>
      text().nullable().references(ProductEntries, #id)();

  // Product snapshot at the time of the sale (`product` JSON of the cart line).
  IntColumn get productLegacyId => integer()();

  TextColumn get productName => text()();

  TextColumn get productCode => text()();

  TextColumn get productBarcode => text()();

  IntColumn get productPriceMinor => integer()();

  TextColumn get productCategory => text()();

  TextColumn get productSub => text()();

  IntColumn get productStock => integer()();

  /// Basis points; the JSON keeps the prototype's percent number.
  IntColumn get productGstBp => integer()();

  IntColumn get productImage => integer()();

  BoolColumn get productFavourite => boolean()();

  // The line itself.
  IntColumn get priceMinor => integer()();

  IntColumn get qtyMilli => integer()();

  IntColumn get discountBp => integer()();

  IntColumn get returnedQtyMilli => integer().withDefault(const Constant(0))();

  TextColumn get createdAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
