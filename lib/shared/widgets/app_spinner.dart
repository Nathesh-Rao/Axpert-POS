import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';
import '../../core/theme/tokens/app_motion.dart';

/// `.spinner`: a ring with a blue arc turning once a second.
class AppSpinner extends StatefulWidget {
  const AppSpinner({required this.size, this.strokeWidth = 3, super.key});

  final double size;
  final double strokeWidth;

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: AppMotion.spinMs),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RotationTransition(
        turns: _controller,
        child: CircularProgressIndicator(
          value: 0.25,
          strokeWidth: widget.strokeWidth,
          color: c.blue,
          backgroundColor: c.spinnerTrack,
        ),
      ),
    );
  }
}
