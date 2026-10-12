import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/entry_metrics.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_entry_tokens.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../controllers/splash_controller.dart';
import '../widgets/entry_logo.dart';

/// Logo, a slim progress bar and nothing else (`splash.png`). A tap or any key
/// press skips to the login.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final SplashController _controller = Get.find<SplashController>();
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: _controller.hold,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    _controller.reducedMotion = reduced;
    if (_started) return;
    _started = true;
    // Reduced motion: no movement, the bar is simply full.
    reduced ? _anim.value = 1 : _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final k = EntryMetrics.of(MediaQuery.sizeOf(context)).scale;
    final logoIn = CurvedAnimation(
      parent: _anim,
      curve: const Interval(
        0,
        AppEntryMotion.splashLogoInMs / AppEntryMotion.splashHoldMs,
        curve: AppEntryMotion.splashLogoInCurve,
      ),
    );
    return Semantics(
      container: true,
      label: context.strings.splashSemantics(),
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          _controller.skip();
          return KeyEventResult.handled;
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _controller.skip,
          child: ColoredBox(
            color: context.entryColors.splashBackground,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  AnimatedBuilder(
                    animation: logoIn,
                    builder: (context, child) => Opacity(
                      opacity: logoIn.value.clamp(0, 1),
                      child: Transform.scale(
                        scale:
                            AppEntryMotion.splashLogoStartScale +
                            (1 - AppEntryMotion.splashLogoStartScale) *
                                logoIn.value,
                        child: child,
                      ),
                    ),
                    child: EntryLogo(size: AppEntrySizes.splashLogo * k),
                  ),
                  SizedBox(height: AppEntrySizes.splashGap * k),
                  ExcludeSemantics(
                    child: AnimatedBuilder(
                      animation: _anim,
                      builder: (context, _) => _ProgressBar(
                        value: _anim.value,
                        track: context.entryColors.splashTrack,
                        scale: k,
                        fill: c.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.value,
    required this.track,
    required this.fill,
    required this.scale,
  });

  final double value;
  final Color track;
  final Color fill;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppEntrySizes.splashBarWidth * scale,
      height: AppEntrySizes.splashBarHeight * scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(AppRadii.full),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
