import 'package:flutter/material.dart';

import '../../core/theme/tokens/app_checkout_sizes.dart';

/// A 1 px dashed horizontal line (`border-top: 1px dashed`), full width.
class DashedDivider extends StatelessWidget {
  const DashedDivider({required this.color, super.key});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter(color)),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      final end = x + AppCheckoutSizes.dashLength;
      canvas.drawLine(
        Offset(x, 0.5),
        Offset(end > size.width ? size.width : end, 0.5),
        paint,
      );
      x += AppCheckoutSizes.dashLength + AppCheckoutSizes.dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
