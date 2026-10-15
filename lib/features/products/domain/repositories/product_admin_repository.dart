import '../entities/packaging_entities.dart';
import '../entities/product_admin_entities.dart';

/// Product management writes (DEC-152). Every method is one transaction:
/// the product, its packagings, barcodes and stock rows commit or roll back
/// together. Controllers re-check the role before calling.
abstract interface class ProductAdminRepository {
  /// Creates a product; returns its `products.id`. Throws
  /// [DuplicateBarcodeException] when a barcode is taken in the store.
  Future<String> create(ProductDraft draft);

  /// Replaces the catalog attributes, packagings and barcodes of [uuid].
  /// Never touches stock.
  Future<void> update(String uuid, ProductDraft draft);

  /// Tombstones the product (and frees its barcodes).
  Future<void> deactivate(String uuid);

  /// Brings it back; throws [DuplicateBarcodeException] when a barcode was
  /// taken meanwhile.
  Future<void> reactivate(String uuid);

  /// The only stock edit path: ledger row, balance and the `products.stock`
  /// cache in one transaction. Throws [AdjustmentBlockedException].
  Future<void> adjustStock({
    required String uuid,
    required int deltaMilli,
    required AdjustmentReason reason,
    required String note,
    String? userId,
  });

  Future<ProductDetail?> detail(int legacyId);

  /// Every product of the store (inactive included), in list order.
  Future<List<CatalogRow>> catalog();

  /// Stock cells by legacy id.
  Future<Map<int, StockView>> stockViews();

  Future<List<CategoryInfo>> categories();

  /// Creates a category (a sub-category with [parentId]); returns it.
  Future<CategoryInfo> createCategory(String name, {String? parentId});
}
