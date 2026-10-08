import 'package:flutter/widgets.dart';

import '../../core/theme/tokens/app_icons.dart';

/// Lucide `star`, optionally filled. The icon font only has the outline, so
/// the fill is a polygon traced from the Lucide star path, drawn under it.
class StarIcon extends StatelessWidget {
  const StarIcon({
    required this.size,
    required this.color,
    this.fill,
    super.key,
  });

  final double size;
  final Color color;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          if (fill != null)
            CustomPaint(
              size: Size.square(size),
              painter: _StarFillPainter(fill!),
            ),
          Icon(AppIcons.star, size: size, color: color),
        ],
      ),
    );
  }
}

class _StarFillPainter extends CustomPainter {
  const _StarFillPainter(this.color);

  final Color color;

  // Vertices of the Lucide 24x24 star (corner arcs flattened).
  static const List<Offset> _points = <Offset>[
    Offset(12, 2.2),
    Offset(14.785, 6.974),
    Offset(16.38, 8.134),
    Offset(21.546, 8.89),
    Offset(21.84, 9.794),
    Offset(18.104, 13.432),
    Offset(17.493, 15.31),
    Offset(18.375, 20.45),
    Offset(17.604, 21.01),
    Offset(12.986, 18.582),
    Offset(11.013, 18.582),
    Offset(6.396, 21.01),
    Offset(5.626, 20.45),
    Offset(6.507, 15.311),
    Offset(5.896, 13.432),
    Offset(2.16, 9.795),
    Offset(2.454, 8.889),
    Offset(7.619, 8.134),
    Offset(9.216, 6.974),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 24;
    final path = Path()
      ..addPolygon(<Offset>[for (final p in _points) p * k], true);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarFillPainter old) => old.color != color;
}
