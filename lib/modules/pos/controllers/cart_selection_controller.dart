import 'dart:async';

import 'package:get/get.dart';

/// Selected cart line, the 1.6 s "just added" highlight and the scroll-to-end
/// request of the cart table. Permanent (the prototype keeps this state in the
/// root component, so it survives page changes and top-bar adds).
class CartSelectionController extends GetxController {
  static const Duration highlightDuration = Duration(milliseconds: 1600);

  final Rxn<int> selected = Rxn<int>();
  final Rxn<int> highlight = Rxn<int>();

  /// Incremented on every highlight; the cart table scrolls to the end.
  final RxInt scrollRequest = 0.obs;

  Timer? _timer;

  void select(int? productId) => selected.value = productId;

  void flash(int productId) {
    highlight.value = productId;
    scrollRequest.value++;
    _timer?.cancel();
    _timer = Timer(highlightDuration, () => highlight.value = null);
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
