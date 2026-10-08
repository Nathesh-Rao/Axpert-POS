/// Sizes of the management pages (Products, Customers, Sales, Reports,
/// Settings) and the shift screens (`css_metrics.md`, `.management`,
/// `.data-table`, `.report-stats`, `.bar-chart`, `.sign-card`).
abstract final class AppManagementSizes {
  /// `.management-heading` margin-bottom
  static const double headingMarginBottom = 28.0;

  /// `.management-heading p` margin-bottom
  static const double eyebrowMarginBottom = 7.0;

  /// `.management>.field` max-width and margin-bottom
  static const double searchMaxWidth = 450.0;
  static const double searchMarginBottom = 22.0;

  /// `.data-table th` / `td` paddings and the table font
  static const double thPadY = 14.0;
  static const double tdPadY = 16.0;
  static const double cellPadX = 11.0;
  static const double thFont = 12.0;
  static const double tdFont = 14.0;

  /// `.stock-ok`, `.stock-low`
  static const double chipPadY = 4.0;
  static const double chipPadX = 10.0;
  static const int lowStockBelow = 10;

  /// `.empty-state` icon of the Sales table
  static const double salesEmptyIcon = 38.0;

  /// `.report-stats`: three tiles, gap and margins, tile padding and value
  static const double reportStatsGap = 15.0;
  static const double reportStatsMarginTop = 30.0;
  static const double reportStatsMarginBottom = 40.0;
  static const double reportTilePadY = 24.0;
  static const double reportTilePadX = 20.0;
  static const double reportValueFont = 27.0;
  static const double reportValueMarginTop = 10.0;

  /// `.bar-chart` rows
  static const double chartMarginY = 25.0;
  static const double chartRowMarginY = 24.0;
  static const double chartGap = 20.0;
  static const double chartLabelWidth = 50.0;
  static const double chartValueMinWidth = 100.0;
  static const double chartTrackHeight = 30.0;
}
