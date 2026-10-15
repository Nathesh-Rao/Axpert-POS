import 'dart:async';

import 'package:get/get.dart';
import '../../../core/session/session_scoped.dart';
import '../models/line_key.dart';

/// Selected cart line, the 1.6 s "just added" highlight and the scroll-to-end
/// request of the cart table. Permanent (the prototype keeps this state in the
/// root component, so it survives page changes and top-bar adds).
class CartSelectionController extends GetxController implements SessionScoped {
  static const Duration highlightDuration = Duration(milliseconds: 1600);

  final Rxn<LineKey> selected = Rxn<LineKey>();
  final Rxn<LineKey> highlight = Rxn<LineKey>();

  /// Incremented on every highlight; the cart table scrolls to the end.
  final RxInt scrollRequest = 0.obs;

  Timer? _timer;

  void select(LineKey? key) => selected.value = key;

  void flash(LineKey key) {
    highlight.value = key;
    scrollRequest.value++;
    _timer?.cancel();
    _timer = Timer(highlightDuration, () => highlight.value = null);
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  @override
  void resetForSignOut() {
    _timer?.cancel();
    selected.value = null;
    highlight.value = null;
  }
}
