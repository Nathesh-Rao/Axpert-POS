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

  /// Narrow variants (cart narrower than [cartNarrowBreak]); 104 keeps `1.000`
  /// on one line between the two stepper buttons.
  static const double colQtyNarrow = 104.0;
  static const double colDiscNarrow = 52.0;
  static const double colTotalNarrow = 80.0;
  static const double colDeleteNarrow = 28.0;

  /// Very narrow variant (cart narrower than [cartVeryNarrowBreak]): only the
  /// item, the quantity and the total; the stepper's minus button turns into
  /// the trash at 1, so no delete column.
  static const double colQtyVeryNarrow = 104.0;
  static const double colTotalVeryNarrow = 72.0;
  static const double colGapVeryNarrow = 4.0;

  /// Stepper and input sizes inside a compact row.
  static const double stepperButton = 26.0;
  static const double stepperHeight = 30.0;
  static const double inputHeight = 30.0;
  static const double deleteButton = 28.0;
  static const double deleteIcon = 16.0;

  /// Slim footer: totals and the four actions in one row.
  static const double cartFooterHeight = 50.0;
  static const double footerButtonHeight = 36.0;
  static const double footerIcon = 16.0;

  /// The edge tab (Cart (n) / Products).
  static const double productsTabWidth = 36.0;
  static const double productsTabIcon = 18.0;

  /// Cart widths below this switch to the narrow compact row (no number,
  /// thumbnail or price column, the unit price moves to the second line;
  /// labels of the footer buttons hidden).
  static const double cartNarrowBreak = 640.0;
  static const double cartVeryNarrowBreak = 440.0;
  static const double cartRowGap = 4;

  /// Three-panel layout (DEC-141): smallest widths a panel may get before the
  /// layout falls back to a smaller state. The cart at 50% or more needs
  /// [cartMinWide], at 25% [cartMinNarrow]; the narrow products panel needs
  /// [productsMinNarrow] (one compact column plus its padding; the search field of the catalog tools
  /// needs about 175).
  static const double cartMinWide = 480.0;
  static const double cartMinNarrow = 280.0;
  static const double productsMinNarrow = 184.0;

  /// A Products panel opening to 75% is laid out at least this wide while it
  /// grows (its header with the customer chip needs the room); it is clipped,
  /// not squeezed.
  static const double productsLayoutWide = 400.0;

  /// Footer below this width stacks in two rows (totals and chip, then the
  /// four actions).
  static const double cartFooterStackBreak = 360.0;

  /// With the invoice-total chip in the row the stack starts earlier.
  static const double cartFooterStackBreakChip = 760.0;
  static const double cartFooterHeightStacked = 92.0;

  /// Billing collapse button and the footer's invoice-total chip.
  static const double billingToggleSize = 28.0;
  static const double billingChipHeight = 32.0;

  /// Edge control: chevron buttons and step dots.
  static const double edgeChevronSize = 28.0;
  static const double edgeDot = 6.0;

  /// Compact catalog tile of the narrow Products panel (DEC-141): at least
  /// this wide, at most [compactMaxColumns] across; the picture and the offer
  /// line have fixed heights so every tile in the grid is the same height.
  static const double compactColumnMin = 104.0;
  static const int compactMaxColumns = 2;
  static const double compactImageHeight = 56.0;
  static const double compactBadgeRow = 22.0;

  /// Customer row narrower than this (the cart at 25%): icon-only Add
  /// Customer button.
  static const double customerRowCompactBreak = 360.0;
}
