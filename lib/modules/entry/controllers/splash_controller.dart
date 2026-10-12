import 'dart:async';

import 'package:get/get.dart';

import '../../../core/theme/tokens/app_entry_tokens.dart';

/// Splash timing and skip. Visuals live in the view; this decides when the
/// splash ends (after [AppEntryMotion.splashHoldMs], or on a tap / key press).
class SplashController extends GetxController {
  SplashController({required this.onDone, Duration? hold})
    : hold = hold ?? const Duration(milliseconds: AppEntryMotion.splashHoldMs);

  /// Navigates on to the login; receives whether motion is reduced.
  final void Function(bool reducedMotion) onDone;
  final Duration hold;

  /// Set by the view from `MediaQuery.disableAnimations` (plain field, not
  /// observable).
  bool reducedMotion = false;

  Timer? _timer;
  bool _finished = false;

  @override
  void onReady() {
    super.onReady();
    _timer = Timer(hold, finish);
  }

  /// Tap or key press.
  void skip() => finish();

  void finish() {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    onDone(reducedMotion);
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
