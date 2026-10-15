import 'package:drift/drift.dart';

import 'packaging_entries.dart';
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

  /// Offer applied to the line (v9, DEC-134); null when none.
  TextColumn get offerKind => text().nullable()();

  TextColumn get offerName => text().nullable()();

  IntColumn get offerSavingMinor => integer().nullable()();

  /// Fixed per-unit reduction of a fixed-amount discount.
  IntColumn get offerUnitOffMinor => integer().nullable()();

  /// A free-item row (price 0).
  BoolColumn get isGift => boolean().withDefault(const Constant(false))();

  /// Packaging the line was sold in (v14, DEC-151); null = base unit.
  /// `qty_milli` is then the package count, `price_minor` the package price.
  TextColumn get packagingId =>
      text().nullable().references(PackagingEntries, #id)();

  /// Unit name at the time of the sale (history survives packaging edits).
  TextColumn get unitName => text().nullable()();

  /// Base units per package at the time of the sale (milli).
  IntColumn get quantityBaseMilli => integer().nullable()();

  /// Base quantity sold (milli): qty x quantity_base_milli, rounded once.
  IntColumn get baseQtyMilli => integer().nullable()();

  IntColumn get returnedQtyMilli => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
