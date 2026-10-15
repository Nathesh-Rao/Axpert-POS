import '../entities/product_admin_entities.dart';

enum ProductIssue {
  nameRequired,
  codeRequired,
  priceNegative,
  unitRequired,
  taxRequired,
  factorInvalid,
  duplicateUnit,
  duplicateBarcode,
  priceOverrideNegative,
  openingNegative,
}

/// One problem found in the form, with the packaging row it belongs to (null
/// for a product-level field).
class ProductProblem {
  const ProductProblem(this.issue, {this.row, this.value});

  final ProductIssue issue;
  final int? row;

  /// The offending barcode for [ProductIssue.duplicateBarcode].
  final String? value;

  @override
  bool operator ==(Object other) =>
      other is ProductProblem &&
      other.issue == issue &&
      other.row == row &&
      other.value == value;

  @override
  int get hashCode => Object.hash(issue, row, value);
}

/// Form rules, plain Dart. The database stays the last line of defence (the
/// partial unique indexes); this gives the friendly, per-field message.
class ProductDraftValidator {
  const ProductDraftValidator();

  List<ProductProblem> validate(ProductDraft draft) {
    final problems = <ProductProblem>[];
    if (draft.name.trim().isEmpty) {
      problems.add(const ProductProblem(ProductIssue.nameRequired));
    }
    if (draft.code.trim().isEmpty) {
      problems.add(const ProductProblem(ProductIssue.codeRequired));
    }
    if (draft.priceMinor < 0) {
      problems.add(const ProductProblem(ProductIssue.priceNegative));
    }
    if (draft.baseUnitId.isEmpty) {
      problems.add(const ProductProblem(ProductIssue.unitRequired));
    }
    if (draft.openingMilli < 0) {
      problems.add(const ProductProblem(ProductIssue.openingNegative));
    }
    final units = <String>{};
    final codes = <String, int?>{};
    for (final code in draft.barcodes) {
      if (code.isEmpty) continue;
      if (codes.containsKey(code)) {
        problems.add(
          ProductProblem(ProductIssue.duplicateBarcode, value: code),
        );
      }
      codes[code] = null;
    }
    for (var i = 0; i < draft.packagings.length; i++) {
      final p = draft.packagings[i];
      if (p.quantityBaseMilli <= 0) {
        problems.add(ProductProblem(ProductIssue.factorInvalid, row: i));
      }
      if (!units.add(p.unitId)) {
        problems.add(ProductProblem(ProductIssue.duplicateUnit, row: i));
      }
      if (p.priceMinor != null && p.priceMinor! < 0) {
        problems.add(
          ProductProblem(ProductIssue.priceOverrideNegative, row: i),
        );
      }
      final code = p.barcode;
      if (code != null && code.isNotEmpty) {
        if (codes.containsKey(code)) {
          problems.add(
            ProductProblem(ProductIssue.duplicateBarcode, row: i, value: code),
          );
        }
        codes[code] = i;
      }
    }
    return problems;
  }
}
