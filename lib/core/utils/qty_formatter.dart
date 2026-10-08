import '../services/pricing/qty.dart';

/// Quantity text from integer milli-units, no floating point.
abstract final class QtyFormatter {
  /// `toFixed(3)`: `1.000`, `2.500`.
  static String fixed3(Qty qty) {
    final negative = qty.milli < 0;
    final digits = (negative ? -qty.milli : qty.milli).toString().padLeft(
      4,
      '0',
    );
    final cut = digits.length - 3;
    return '${negative ? '-' : ''}${digits.substring(0, cut)}.${digits.substring(cut)}';
  }

  /// JavaScript number-to-string for a 3-decimal value: `1`, `1.5`, `0.001`
  /// (what the prototype's `"x" + line.qty` shows).
  static String compact(Qty qty) {
    final text = fixed3(qty);
    final trimmed = text.replaceFirst(RegExp(r'\.?0+$'), '');
    return trimmed.isEmpty || trimmed == '-' ? '0' : trimmed;
  }
}
