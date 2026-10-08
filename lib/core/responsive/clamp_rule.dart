/// CSS `clamp(min, k * vw, max)` and `clamp(min, k * vh, max)` for a window of
/// [width] x [height] logical px. [k] is the CSS number before `vw`/`vh`.
class ClampRule {
  const ClampRule(this.width, this.height);

  final double width;
  final double height;

  double vw(double min, double k, double max) =>
      (width * k / 100).clamp(min, max);

  double vh(double min, double k, double max) =>
      (height * k / 100).clamp(min, max);
}
