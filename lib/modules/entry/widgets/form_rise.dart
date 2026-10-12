import 'package:flutter/material.dart';

import '../../../core/theme/tokens/app_entry_tokens.dart';

/// Fades the login form up into place after a short delay, so it arrives
/// while the logo is still flying in. With reduced motion it is just there.
class FormRise extends StatefulWidget {
  const FormRise({required this.child, super.key});

  final Widget child;

  @override
  State<FormRise> createState() => _FormRiseState();
}

class _FormRiseState extends State<FormRise>
    with SingleTickerProviderStateMixin {
  static const int _total =
      AppEntryMotion.formRiseDelayMs + AppEntryMotion.formRiseMs;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _total),
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _anim,
    curve: const Interval(
      AppEntryMotion.formRiseDelayMs / _total,
      1,
      curve: AppEntryMotion.formRiseCurve,
    ),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    MediaQuery.disableAnimationsOf(context) ? _anim.value = 1 : _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, AppEntryMotion.formRiseOffset * (1 - _curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
