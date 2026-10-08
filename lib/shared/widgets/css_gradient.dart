import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// CSS `linear-gradient(<angle>deg, ...)` for a box of [size].
/// 0deg points up, 90deg points right; the gradient line has the CSS length
/// `|w sin a| + |h cos a|` so corners get the end colors.
LinearGradient cssLinearGradient(
  double angleDeg,
  List<Color> colors,
  Size size,
) {
  final a = angleDeg * math.pi / 180;
  final dx = math.sin(a);
  final dy = -math.cos(a);
  final w = size.width <= 0 ? 1.0 : size.width;
  final h = size.height <= 0 ? 1.0 : size.height;
  final length = (w * dx).abs() + (h * dy).abs();
  final end = Alignment(dx * length / w, dy * length / h);
  return LinearGradient(
    begin: Alignment(-end.x, -end.y),
    end: end,
    colors: colors,
  );
}

/// A box painted with a CSS-angled linear gradient.
class CssGradientBox extends StatelessWidget {
  const CssGradientBox({
    required this.angleDeg,
    required this.colors,
    this.borderRadius,
    this.border,
    this.padding,
    this.child,
    super.key,
  });

  final double angleDeg;
  final List<Color> colors;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final EdgeInsetsGeometry? padding;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: cssLinearGradient(
              angleDeg,
              colors,
              Size(
                size.width.isFinite ? size.width : 0,
                size.height.isFinite ? size.height : 0,
              ),
            ),
            borderRadius: borderRadius,
            border: border,
          ),
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        );
      },
    );
  }
}
