import 'dart:async';

import 'package:get/get.dart';

/// Permanent one-second clock. The timer only runs while at least one widget
/// is attached (the cart heading, the Reports page), so idle pages and tests
/// keep no timer. [now] is the tick signal; [current] is the real time.
class ClockController extends GetxController {
  ClockController({DateTime Function()? now}) : _nowFn = now ?? DateTime.now {
    this.now = _nowFn().obs;
  }

  final DateTime Function() _nowFn;
  late final Rx<DateTime> now;

  /// The current time (not the once-a-second [now] value).
  DateTime get current => _nowFn();

  Timer? _timer;
  int _attached = 0;

  /// Starts the ticks. It never writes [now]: `attach` runs inside widget
  /// build (initState) and controller creation, where a write would notify
  /// observers that are mounted at that moment. Widgets show [current] when
  /// they rebuild and use [now] only as the once-a-second signal.
  void attach() {
    _attached++;
    _timer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => now.value = _nowFn(),
    );
  }

  void detach() {
    if (_attached > 0) _attached--;
    if (_attached == 0) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
