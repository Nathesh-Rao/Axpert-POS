import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Owns the global search field's focus node and text so both survive page
/// navigation. [refocus] mirrors the prototype's `focus()` (40 ms delay).
class SearchFieldController extends GetxController {
  static const Duration refocusDelay = Duration(milliseconds: 40);

  final FocusNode focusNode = FocusNode(debugLabel: 'global-search');
  final TextEditingController text = TextEditingController();

  Timer? _timer;

  void focus() => focusNode.requestFocus();

  void refocus() {
    _timer?.cancel();
    _timer = Timer(refocusDelay, focus);
  }

  @override
  void onClose() {
    _timer?.cancel();
    focusNode.dispose();
    text.dispose();
    super.onClose();
  }
}
