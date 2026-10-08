import '../../../core/services/pricing/basis_points.dart';
import '../../../core/services/pricing/currency.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/pricing_models.dart';
import '../../../core/utils/decimal_input.dart';
import '../../../core/utils/decimal_text.dart';

/// The bill discount drawer's number rules as plain Dart (no floats).
///
/// Prototype: `value = max(0, min(max, Number(text)))` on every keystroke with
/// `max = 100` (percent) or `totals.subtotal` (flat: the gross value, KG-121).
/// An empty field is `Number("") = 0`. Values are scaled integers: basis
/// points for a percent (2 decimals), minor units for a flat amount.
abstract final class DiscountRules {
  static const int percentScale = 2;

  static int scaleOf(BillDiscountType type, Currency currency) =>
      type == BillDiscountType.percent ? percentScale : currency.exponent;

  /// The largest value the field accepts.
  static int maxScaled(BillDiscountType type, {required Money subtotal}) =>
      type == BillDiscountType.percent ? Bp.full.value : subtotal.minor;

  /// The typed text as a clamped scaled value (empty or not a number is 0).
  static int clampScaled(
    BillDiscountType type,
    String text, {
    required Money subtotal,
  }) {
    final scale = scaleOf(type, subtotal.currency);
    final typed = DecimalInput.tryScaled(text, scale) ?? 0;
    final max = maxScaled(type, subtotal: subtotal);
    if (typed < 0) return 0;
    return typed > max ? max : typed;
  }

  /// The typed text as the prototype's `discountForm.value` holds it when the
  /// type was switched after typing: not clamped to the new type's range
  /// (KG-122). Empty or not a number is 0, negatives are 0.
  static int clampScaledUnbounded(
    BillDiscountType type,
    String text, {
    required Currency currency,
  }) {
    final typed = DecimalInput.tryScaled(text, scaleOf(type, currency)) ?? 0;
    return typed < 0 ? 0 : typed;
  }

  /// The text the field shows after a keystroke: the typed text when it is
  /// within range (React leaves "5." alone), the clamped number otherwise,
  /// and "0" for an emptied field.
  static String shown(
    BillDiscountType type,
    String text, {
    required Money subtotal,
  }) {
    final scale = scaleOf(type, subtotal.currency);
    final typed = DecimalInput.tryScaled(text, scale);
    final clamped = clampScaled(type, text, subtotal: subtotal);
    // A lone "." is still being typed: leave it (it counts as 0).
    if (typed == null && text.trim().isNotEmpty) return text;
    // Compare three digits finer so 40.001 against 40.00 counts as above.
    const fine = 1000;
    final exact = DecimalInput.tryScaled(text, scale + 3);
    final inRange =
        exact != null &&
        exact >= 0 &&
        exact <= maxScaled(type, subtotal: subtotal) * fine;
    if (inRange) return text;
    return DecimalText.scaled(clamped, scale);
  }

  /// The value as the cart stores it.
  static BillDiscount toDiscount(
    BillDiscountType type,
    int scaled,
    Currency currency,
  ) => type == BillDiscountType.percent
      ? BillDiscount.percent(Bp(scaled))
      : BillDiscount.flat(Money(scaled, currency));

  /// The text the drawer opens with: the stored value as a number.
  static String textOf(BillDiscount discount, Currency currency) {
    if (discount.type == BillDiscountType.percent) {
      return DecimalText.scaled(discount.percent.value, percentScale);
    }
    return DecimalText.scaled(discount.flat?.minor ?? 0, currency.exponent);
  }
}
