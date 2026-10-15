import '../../../core/constants/app_strings.dart';
import '../../../core/services/packaging/stock_formatter.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../core/utils/qty_formatter.dart';

/// "3 Carton + 5 Piece" for a base quantity, from the packaging levels.
String stockText(
  AppStrings s,
  int baseMilli,
  List<({String name, int quantityBaseMilli})> levels,
  String baseUnitName,
) {
  final breakdown = const StockFormatter().breakdown(baseMilli, [
    for (final l in levels)
      StockLevel(name: l.name, quantityBaseMilli: l.quantityBaseMilli),
  ], baseUnitName: baseUnitName);
  final text = breakdown.parts
      .map(
        (p) => s.stockPart(QtyFormatter.compact(Qty(p.quantityMilli)), p.name),
      )
      .join(s.stockPartsJoin());
  return breakdown.negative ? '${s.stockNegativeMark()}$text' : text;
}
