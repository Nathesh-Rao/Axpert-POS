import '../theme/tokens/app_density_sizes.dart';
import 'breakpoints.dart';

/// Column widths of the desktop cart table (DEC-138). The head and every row
/// read the same instance, so their columns line up; the item column takes
/// the rest of the width.
class CartCompactColumns {
  const CartCompactColumns({
    required this.index,
    required this.thumb,
    required this.qty,
    required this.price,
    required this.disc,
    required this.total,
    required this.delete,
    required this.gap,
    required this.narrow,
    this.veryNarrow = false,
  });

  /// [cartWidth] is the width of the table area; below
  /// `AppDensitySizes.cartNarrowBreak` the narrow variant is used (smaller
  /// inputs, no thumbnail). The thumbnail also hides when the window is short
  /// (height <= 719).
  factory CartCompactColumns.forSize({
    required double cartWidth,
    required double windowHeight,
  }) {
    final narrow = cartWidth < AppDensitySizes.cartNarrowBreak;
    if (cartWidth < AppDensitySizes.cartVeryNarrowBreak) {
      return const CartCompactColumns(
        index: 0,
        thumb: 0,
        qty: AppDensitySizes.colQtyVeryNarrow,
        price: 0,
        disc: 0,
        total: AppDensitySizes.colTotalVeryNarrow,
        delete: 0,
        gap: AppDensitySizes.colGapVeryNarrow,
        narrow: true,
        veryNarrow: true,
      );
    }
    final showThumb = !narrow && !Breakpoints.heightAtMost719(windowHeight);
    return CartCompactColumns(
      index: narrow ? 0 : AppDensitySizes.colIndex,
      thumb: showThumb ? AppDensitySizes.colThumb : 0,
      qty: narrow ? AppDensitySizes.colQtyNarrow : AppDensitySizes.colQty,
      price: narrow ? 0 : AppDensitySizes.colPrice,
      disc: narrow ? AppDensitySizes.colDiscNarrow : AppDensitySizes.colDisc,
      total: narrow ? AppDensitySizes.colTotalNarrow : AppDensitySizes.colTotal,
      delete: narrow
          ? AppDensitySizes.colDeleteNarrow
          : AppDensitySizes.colDelete,
      gap: AppDensitySizes.colGap,
      narrow: narrow,
    );
  }

  final double index;

  /// 0 when the number column is hidden (narrow cart).
  /// Thumbnail width, 0 when the thumbnail column is hidden.
  final double thumb;
  final double qty;
  final double price;
  final double disc;
  final double total;
  final double delete;
  final double gap;
  final bool narrow;

  /// Below `cartVeryNarrowBreak`: item, quantity and total only.
  final bool veryNarrow;

  bool get showDisc => disc > 0;
  bool get showDelete => delete > 0;
  bool get showThumb => thumb > 0;
  bool get showIndex => index > 0;
  bool get showPrice => price > 0;
}
