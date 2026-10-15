import '../entities/packaging_entities.dart';

abstract interface class UnitRepository {
  Future<List<MeasureUnit>> all();

  Future<MeasureUnit?> byCode(String code);
}

abstract interface class BrandRepository {
  Future<List<Brand>> all();

  /// Insert or update by id.
  Future<void> save(Brand brand);

  /// Tombstone (the row stays).
  Future<void> remove(String id);
}

abstract interface class PackagingRepository {
  /// Live packagings of a product (disabled ones included), by sort order.
  Future<List<ProductPackaging>> forProduct(String productId);

  /// Insert or update by id. Throws [DuplicatePackagingException] when the
  /// product already has another live packaging of the same unit.
  Future<void> save(ProductPackaging packaging);

  /// Tombstone (the row stays; the unit can be added again).
  Future<void> remove(String id);
}

abstract interface class BarcodeRepository {
  /// The live barcode [barcode] in [storeId]'s scope (a null store matches
  /// any scope), or null. A scan resolves to the product and, for a pack or
  /// carton code, its packaging.
  Future<BarcodeMatch?> findByBarcode(String? storeId, String barcode);

  Future<List<ProductBarcode>> forProduct(String productId);

  /// Insert or update by id. Throws [DuplicateBarcodeException] when another
  /// live row has the same barcode in the same store scope.
  Future<void> save(ProductBarcode barcode);

  /// Tombstone (the row stays).
  Future<void> remove(String id);
}
