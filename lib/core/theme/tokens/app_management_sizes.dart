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

  /// `.settings-content` max-width
  static const double settingsMaxWidth = 600.0;

  /// `.avatar.large`: size, font and margin-bottom
  static const double avatarLarge = 65.0;
  static const double avatarLargeFont = 32.0;
  static const double avatarLargeMarginBottom = 20.0;
  static const double avatarBorder = 2.0;

  /// `.modal-symbol` power icon of the shift-close dialog
  static const double closeSymbolIcon = 29.0;

  /// `.sign-card`: padding, title size, margins; brand mark width and font
  static const double signCardPad = 50.0;
  static const double signTitleFont = 29.0;
  static const double signTitleMarginBottom = 13.0;
  static const double signBodyMarginBottom = 25.0;
  static const double signMarkMarginBottom = 25.0;
  static const double signMarkWidth = 63.0;
  static const double signMarkFont = 42.0;

  /// Sales table min-content widths (the longest unbreakable word at the
  /// 14 px table font, measured once; the columns never go below them)
  static const double salesMinBill = 62.0;
  static const double salesMinDate = 78.0;
  static const double salesMinCustomer = 46.0;
  static const double salesMinMode = 40.0;
  static const double salesMinTotal = 60.0;
  static const double salesMinAction = 42.0;

  /// `.returns` max-width, `h3` and `p` margins, `.return-line` padding,
  /// `.return-line input`, `.returns .primary` margin-top
  static const double returnsMaxWidth = 550.0;
  static const double returnsTitleMarginBottom = 18.0;
  static const double returnsParagraphMarginY = 18.0;
  static const double returnLinePadY = 17.0;
  static const double returnInputWidth = 80.0;
  static const double returnInputHeight = 36.0;
  static const double returnInputPad = 8.0;
  static const double returnsButtonMarginTop = 20.0;

  /// Customers table min-content widths (see the Sales ones above)
  static const double customersMinName = 50.0;
  static const double customersMinPhone = 80.0;
  static const double customersMinEmail = 96.0;
  static const double customersMinMembership = 60.0;
  static const double customersMinPoints = 44.0;
}
