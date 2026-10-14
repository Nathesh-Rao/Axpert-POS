/// Side rail card (desktop and web; touch keeps the labelled rail, see
/// `AppDensitySizes.railWidth`). Two sets: normal, and narrow for windows
/// <= 1280 wide.
class AppRailSizes {
  const AppRailSizes._({
    required this.width,
    required this.item,
    required this.padX,
  });

  static const AppRailSizes normal = AppRailSizes._(
    width: 56.0,
    item: 44.0,
    padX: 6.0,
  );

  static const AppRailSizes narrow = AppRailSizes._(
    width: 48.0,
    item: 40.0,
    padX: 4.0,
  );

  static AppRailSizes of({required bool narrow}) =>
      narrow ? AppRailSizes.narrow : AppRailSizes.normal;

  /// Card width.
  final double width;

  /// Square hit target of one item.
  final double item;

  /// Horizontal padding of the card.
  final double padX;

  /// Top and bottom padding of the card.
  static const double padY = 8.0;

  /// Gap between two items.
  static const double itemGap = 4.0;

  /// One icon size for every item.
  static const double icon = 22.0;

  /// Divider thickness and the space above and below it.
  static const double dividerThickness = 1.0;
  static const double dividerMargin = 8.0;

  /// Margin left of the card and gap between the card and the work area.
  static const double margin = 8.0;

  /// Slot of a future count badge (top-right corner of the item).
  static const double badgeSlot = 8.0;
}
