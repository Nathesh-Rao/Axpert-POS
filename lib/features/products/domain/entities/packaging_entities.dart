/// A unit of measure (DEC-151): piece, kg, litre...
class MeasureUnit {
  const MeasureUnit({
    required this.id,
    required this.code,
    required this.name,
    required this.kind,
  });

  factory MeasureUnit.fromJson(Map<String, dynamic> json) => MeasureUnit(
    id: json['id'] as String,
    code: json['code'] as String,
    name: json['name'] as String,
    kind: UnitKind.fromCode(json['kind'] as String),
  );

  final String id;
  final String code;
  final String name;
  final UnitKind kind;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'code': code,
    'name': name,
    'kind': kind.code,
  };
}

enum UnitKind {
  count('count'),
  weight('weight'),
  volume('volume');

  const UnitKind(this.code);

  final String code;

  static UnitKind fromCode(String code) =>
      values.firstWhere((k) => k.code == code);
}

class Brand {
  const Brand({required this.id, required this.name});

  factory Brand.fromJson(Map<String, dynamic> json) =>
      Brand(id: json['id'] as String, name: json['name'] as String);

  final String id;
  final String name;

  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'name': name};
}

/// A packaging level of a product: a pack of 6, a carton of 24.
class ProductPackaging {
  const ProductPackaging({
    required this.id,
    required this.productId,
    required this.unitId,
    required this.name,
    required this.quantityBaseMilli,
    this.sku,
    this.priceMinor,
    this.sortOrder = 0,
    this.enabled = true,
  });

  factory ProductPackaging.fromJson(Map<String, dynamic> json) =>
      ProductPackaging(
        id: json['id'] as String,
        productId: json['productId'] as String,
        unitId: json['unitId'] as String,
        name: json['name'] as String,
        quantityBaseMilli: json['quantityBaseMilli'] as int,
        sku: json['sku'] as String?,
        priceMinor: json['priceMinor'] as int?,
        sortOrder: json['sortOrder'] as int? ?? 0,
        enabled: json['enabled'] as bool? ?? true,
      );

  /// `products.id` (the UUID, not the legacy list id).
  final String productId;
  final String id;
  final String unitId;
  final String name;

  /// Base units per package, in milli-units (24000 = 24).
  final int quantityBaseMilli;
  final String? sku;

  /// Null = derived (base price x quantity), see `PackagingService`.
  final int? priceMinor;
  final int sortOrder;
  final bool enabled;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'productId': productId,
    'unitId': unitId,
    'name': name,
    'quantityBaseMilli': quantityBaseMilli,
    'sku': sku,
    'priceMinor': priceMinor,
    'sortOrder': sortOrder,
    'enabled': enabled,
  };
}

/// A barcode of a product; [packagingId] null means the base unit.
class ProductBarcode {
  const ProductBarcode({
    required this.id,
    required this.productId,
    required this.barcode,
    this.packagingId,
    this.storeId,
  });

  factory ProductBarcode.fromJson(Map<String, dynamic> json) => ProductBarcode(
    id: json['id'] as String,
    productId: json['productId'] as String,
    barcode: json['barcode'] as String,
    packagingId: json['packagingId'] as String?,
    storeId: json['storeId'] as String?,
  );

  final String id;
  final String productId;
  final String barcode;
  final String? packagingId;

  /// The product's store (null = unscoped).
  final String? storeId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'productId': productId,
    'barcode': barcode,
    'packagingId': packagingId,
    'storeId': storeId,
  };
}

/// What a scanned barcode points at: the product and, when the code belongs
/// to a pack or carton, that packaging (null = base unit). The caller
/// resolves [productLegacyId] to a `Product` and checks `packaging.enabled`.
class BarcodeMatch {
  const BarcodeMatch({
    required this.productId,
    required this.productLegacyId,
    required this.barcode,
    this.packaging,
  });

  final String productId;
  final int productLegacyId;
  final String barcode;
  final ProductPackaging? packaging;
}

/// A barcode is already used by another live row in the same store scope.
class DuplicateBarcodeException implements Exception {
  const DuplicateBarcodeException(this.barcode);

  final String barcode;

  @override
  String toString() => 'DuplicateBarcodeException($barcode)';
}

/// The product already has a live packaging of this unit.
class DuplicatePackagingException implements Exception {
  const DuplicatePackagingException(this.productId, this.unitId);

  final String productId;
  final String unitId;

  @override
  String toString() => 'DuplicatePackagingException($productId, $unitId)';
}

/// What the sales screen can sell of one product besides the base unit: the
/// base unit's name and its ENABLED packagings (DEC-154).
class SellableUnits {
  const SellableUnits({required this.baseUnitName, required this.packagings});

  final String baseUnitName;
  final List<ProductPackaging> packagings;
}
