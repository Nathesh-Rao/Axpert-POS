/// Text of an integer scaled by `10^scale` as JavaScript prints the number
/// (`2000, 2` -> `20`, `2050, 2` -> `20.5`), with no floating point.
abstract final class DecimalText {
  static String scaled(int value, int scale) {
    final negative = value < 0;
    final digits = (negative ? -value : value).toString().padLeft(
      scale + 1,
      '0',
    );
    final cut = digits.length - scale;
    var frac = digits.substring(cut).replaceFirst(RegExp(r'0+$'), '');
    final whole = digits.substring(0, cut);
    final text = frac.isEmpty ? whole : '$whole.$frac';
    return negative ? '-$text' : text;
  }

  /// [value] scaled by `10^scale` with exactly [scale] decimals (`2050, 2` ->
  /// `20.50`, `7, 0` -> `7`).
  static String fixed(int value, int scale) {
    if (scale == 0) return value.toString();
    final negative = value < 0;
    final digits = (negative ? -value : value).toString().padLeft(
      scale + 1,
      '0',
    );
    final cut = digits.length - scale;
    return '${negative ? '-' : ''}${digits.substring(0, cut)}.${digits.substring(cut)}';
  }
}
