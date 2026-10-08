import 'dart:async';

import 'package:get/get.dart';

/// Permanent one-second clock. The timer only runs while at least one widget
/// is attached (the cart heading), so idle pages and tests keep no timer.
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

  void attach() {
    _attached++;
    now.value = _nowFn();
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
