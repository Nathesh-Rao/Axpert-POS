import '../services/product_draft_validator.dart';
import '../../../offers/domain/entities/offer_draft.dart';
import '../../../offers/domain/services/offer_draft_rules.dart';
import 'packaging_entities.dart';
import 'product.dart';

/// A category or sub-category row (DEC-132); a null [parentId] is a top one.
class CategoryInfo {
  const CategoryInfo({required this.id, required this.name, this.parentId});

  final String id;
  final String name;
  final String? parentId;
}

/// One packaging row of the form. [id] is null for a new row.
class PackagingDraft {
  const PackagingDraft({
    required this.unitId,
    required this.name,
    required this.quantityBaseMilli,
    this.id,
    this.sku,
    this.barcode,
    this.priceMinor,
    this.enabled = true,
  });

  final String? id;
  final String unitId;

  /// The unit name shown on the receipt ("Carton").
  final String name;
  final int quantityBaseMilli;
  final String? sku;
  final String? barcode;

  /// Null = derived from the base price (`PackagingService`).
  final int? priceMinor;
  final bool enabled;
}

/// Everything the product form saves (no stock after create: that is an
/// adjustment, DEC-152). Money is minor units of the store currency, rates
/// are basis points, quantities milli-units.
class ProductDraft {
  const ProductDraft({
    required this.name,
    required this.code,
    required this.priceMinor,
    required this.gstBp,
    required this.baseUnitId,
    this.categoryId,
    this.category = '',
    this.sub = '',
    this.brandId,
    this.barcodes = const <String>[],
    this.packagings = const <PackagingDraft>[],
    this.openingMilli = 0,
    this.offers = const <OfferDraft>[],
  });

  final String name;
  final String code;
  final int priceMinor;
  final int gstBp;
  final String baseUnitId;

  /// Top-level category row (null = none) and the names kept on the product.
  final String? categoryId;
  final String category;
  final String sub;
  final String? brandId;

  /// Base-unit barcodes; the first one is the cached `products.barcode`.
  final List<String> barcodes;
  final List<PackagingDraft> packagings;

  /// Opening stock (create only), base milli-units.
  final int openingMilli;

  /// The product's offers (DEC-153), saved in the same transaction.
  final List<OfferDraft> offers;
}

/// A product with its catalog attributes, for the edit form.
class ProductDetail {
  const ProductDetail({
    required this.uuid,
    required this.product,
    required this.baseUnitId,
    required this.brandId,
    required this.categoryId,
    required this.barcodes,
    required this.packagings,
    required this.packagingBarcodes,
    required this.offers,
    required this.balanceMilli,
    required this.active,
  });

  final String uuid;
  final Product product;
  final String baseUnitId;
  final String? brandId;
  final String? categoryId;
  final List<String> barcodes;
  final List<ProductPackaging> packagings;

  /// Barcode of each packaging that has one, by packaging id.
  final Map<String, String> packagingBarcodes;

  /// Live offers of the product (inactive and expired ones included).
  final List<OfferDraft> offers;

  /// Exact stock (the ledger balance, base milli-units).
  final int balanceMilli;
  final bool active;
}

/// What the table needs to show a stock cell: exact balance, packaging levels.
class StockView {
  const StockView({
    required this.balanceMilli,
    required this.baseUnitName,
    required this.levels,
  });

  final int balanceMilli;
  final String baseUnitName;

  /// Enabled packagings (name, base milli per package).
  final List<({String name, int quantityBaseMilli})> levels;
}

/// Why a stock adjustment is made (the ledger reason).
enum AdjustmentReason { countCorrection, damage, received, other }

/// A product row of the Products table including inactive ones.
class CatalogRow {
  const CatalogRow({required this.product, required this.active});

  final Product product;
  final bool active;
}

/// The form was saved with problems the validator would have caught.
class InvalidProductException implements Exception {
  const InvalidProductException(this.problems);

  final List<ProductProblem> problems;

  @override
  String toString() => 'InvalidProductException($problems)';
}

/// An offer of the form cannot be stored ([index] is its place in the list).
class InvalidOfferException implements Exception {
  const InvalidOfferException(this.index, this.issues);

  final int index;
  final List<OfferIssue> issues;

  @override
  String toString() => 'InvalidOfferException($index, $issues)';
}

/// The user's role may not change the catalog.
class PermissionDeniedException implements Exception {
  const PermissionDeniedException();

  @override
  String toString() => 'PermissionDeniedException';
}

/// The adjustment would take the stock below zero in a store that forbids it.
class AdjustmentBlockedException implements Exception {
  const AdjustmentBlockedException(this.availableMilli);

  final int availableMilli;

  @override
  String toString() => 'AdjustmentBlockedException($availableMilli)';
}
