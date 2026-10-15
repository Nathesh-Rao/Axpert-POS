import '../../../core/services/packaging/packaging_ref.dart';
import '../../../core/services/pricing/money.dart';

/// One way to sell a product: the base unit or one enabled packaging, with
/// the price of one such unit (DEC-154).
class UnitOption {
  const UnitOption({
    required this.name,
    required this.factorMilli,
    required this.price,
    this.packaging,
  });

  /// "Piece", "Pack", "Carton".
  final String name;

  /// Base units per unit (milli); 1000 for the base unit.
  final int factorMilli;

  /// Price of one unit of this option (the package price for a packaging).
  final Money price;

  /// The snapshot copied onto the line; null for the base unit.
  final PackagingRef? packaging;

  bool get isBase => packaging == null;

  String? get packagingId => packaging?.id;
}
