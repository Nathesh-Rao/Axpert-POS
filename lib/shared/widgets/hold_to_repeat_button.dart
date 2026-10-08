import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'app_pressable.dart';

/// Button that repeats [onAction] while held: first after 500 ms, then every
/// 140 ms (prototype `RepeatButton`). A plain click runs it once; the click
/// that ends a hold does not run it again.
class HoldToRepeatButton extends StatefulWidget {
  const HoldToRepeatButton({
    required this.onAction,
    required this.builder,
    required this.tooltip,
    required this.borderRadius,
    super.key,
  });

  static const Duration holdDelay = Duration(milliseconds: 500);
  static const Duration repeatInterval = Duration(milliseconds: 140);

  final VoidCallback onAction;
  final Widget Function(BuildContext context, bool hovered) builder;
  final String tooltip;
  final double borderRadius;

  @override
  State<HoldToRepeatButton> createState() => _HoldToRepeatButtonState();
}

class _HoldToRepeatButtonState extends State<HoldToRepeatButton> {
  Timer? _delay;
  Timer? _interval;
  bool _repeated = false;

  void _stop() {
    _delay?.cancel();
    _interval?.cancel();
    _delay = null;
    _interval = null;
  }

  void _down(PointerDownEvent event) {
    if (event.buttons != kPrimaryButton) return;
    _stop();
    _repeated = false;
    _delay = Timer(HoldToRepeatButton.holdDelay, () {
      _repeated = true;
      widget.onAction();
      _interval = Timer.periodic(
        HoldToRepeatButton.repeatInterval,
        (_) => widget.onAction(),
      );
    });
  }

  void _click() {
    if (!_repeated) widget.onAction();
    _repeated = false;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _down,
      onPointerUp: (_) => _stop(),
      onPointerCancel: (_) => _stop(),
      child: AppPressable(
        tooltip: widget.tooltip,
        onTap: _click,
        borderRadius: widget.borderRadius,
        builder: widget.builder,
      ),
    );
  }
}
