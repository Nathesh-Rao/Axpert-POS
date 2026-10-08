/// Media-query thresholds of the prototype (`max-width` / `max-height`, so a
/// window exactly at the threshold counts as "at or below").
abstract final class Breakpoints {
  static const double width1700 = 1700;
  static const double width1280 = 1280;
  static const double width1100 = 1100;
  static const double height960 = 960;
  static const double height820 = 820;
  static const double height719 = 719;

  static bool widthAtMost1700(double w) => w <= width1700;
  static bool widthAtMost1280(double w) => w <= width1280;
  static bool widthAtMost1100(double w) => w <= width1100;
  static bool heightAtMost960(double h) => h <= height960;
  static bool heightAtMost820(double h) => h <= height820;
  static bool heightAtMost719(double h) => h <= height719;
}
