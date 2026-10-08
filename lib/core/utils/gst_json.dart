import '../services/pricing/basis_points.dart';

/// The prototype keeps `gst` as a plain percent number (18, 12, 5). JSON is
/// converted to basis points by decimal-string parsing, never a float multiply
/// (DEC-023).
abstract final class GstJson {
  static Bp parse(Object? json) => Bp.parsePercent('${json ?? 0}');

  /// Whole percentages stay ints; fractional ones go out as a decimal number.
  static Object toJson(Bp bp) {
    if (bp.value % 100 == 0) return bp.value ~/ 100;
    final whole = bp.value ~/ 100;
    final frac = (bp.value % 100).toString().padLeft(2, '0');
    final text = '$whole.$frac'.replaceFirst(RegExp(r'0+$'), '');
    return double.parse(text);
  }
}
