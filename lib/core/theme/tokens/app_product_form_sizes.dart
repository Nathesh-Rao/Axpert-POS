/// Sizes of the product form and the stock dialog (DEC-152). The form has no
/// prototype counterpart; every value is derived from the modal tokens.
abstract final class AppProductFormSizes {
  /// Wide modal: two columns of the 460 px modal plus the gap.
  static const double formWidth = 940;

  /// The stock dialog is the regular modal width (`AppSizes.modalWidth`).
  static const double toggleBox = 22;
  static const double toggleIcon = 15;

  /// Width of a count box in the stock entry ("3 [carton]").
  static const double countWidth = 84;

  /// Width of the unit dropdown in a packaging row.
  static const double unitWidth = 150;

  /// Width of the factor box in a packaging row.
  static const double factorWidth = 120;

  /// Width of the SKU and price boxes in a packaging row.
  static const double smallFieldWidth = 130;

  /// Width of the offer name box and of the minimum cart value box.
  static const double offerNameWidth = 300;
  static const double minCartWidth = 210;
}
