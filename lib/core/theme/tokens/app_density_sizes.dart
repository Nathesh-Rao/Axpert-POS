/// Sizes of the desktop cart-first POS layout (DEC-138): the compact cart rows,
/// the slim footer and the collapsible Products panel. Approved deviations from
/// the prototype, so they are NOT part of `AppSizes.all` (that map mirrors the
/// prototype's CSS and is tested against `docs/css_metrics.md`).
abstract final class AppDensitySizes {
  /// Height of one cart row and of one gift row.
  static const double cartRowHeight = 48.0;
  static const double cartRowThumb = 34.0;
  static const double cartRowHairline = 1.0;

  /// Left accent of the selected row.
  static const double cartRowAccent = 2.0;

  /// Compact table columns (the head uses the same widths).
  static const double colIndex = 28.0;
  static const double colThumb = 36.0;
  static const double colQty = 112.0;
  static const double colPrice = 84.0;
  static const double colDisc = 64.0;
  static const double colTotal = 96.0;
  static const double colDelete = 32.0;
  static const double colGap = 8.0;

  /// Narrow variants (cart narrower than [cartNarrowBreak]).
  static const double colQtyNarrow = 92.0;
  static const double colDiscNarrow = 52.0;
  static const double colTotalNarrow = 80.0;
  static const double colDeleteNarrow = 28.0;

  /// Stepper and input sizes inside a compact row.
  static const double stepperButton = 26.0;
  static const double stepperHeight = 30.0;
  static const double inputHeight = 30.0;
  static const double deleteButton = 28.0;
  static const double deleteIcon = 16.0;

  /// Slim footer: totals and the four actions in one row.
  static const double cartFooterHeight = 40.0;
  static const double footerButtonHeight = 36.0;
  static const double footerIcon = 16.0;

  /// The edge tab (Cart (n) / Products).
  static const double productsTabWidth = 36.0;
  static const double productsTabIcon = 18.0;

  /// Cart widths below this switch to the narrow compact row (no number,
  /// thumbnail or price column, the unit price moves to the second line;
  /// labels of the footer buttons hidden).
  static const double cartNarrowBreak = 640.0;
}
