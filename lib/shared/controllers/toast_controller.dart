import 'dart:async';

import 'package:get/get.dart';

enum ToastKind { success, error, warning, info }

class ToastItem {
  const ToastItem({
    required this.id,
    required this.text,
    required this.kind,
    this.onUndo,
  });

  final int id;
  final String text;
  final ToastKind kind;
  final void Function()? onUndo;
}

/// Toast queue: the last four are kept, each disappears after 5 s.
class ToastController extends GetxController {
  static const int maxVisible = 4;
  static const Duration lifetime = Duration(seconds: 5);

  final RxList<ToastItem> toasts = <ToastItem>[].obs;

  final Map<int, Timer> _timers = <int, Timer>{};
  int _nextId = 0;

  int show(
    String text, {
    ToastKind kind = ToastKind.success,
    void Function()? onUndo,
  }) {
    final id = _nextId++;
    final kept = toasts.length >= maxVisible
        ? toasts.sublist(toasts.length - (maxVisible - 1))
        : toasts.toList();
    for (final dropped in toasts.where((t) => !kept.contains(t))) {
      _timers.remove(dropped.id)?.cancel();
    }
    toasts.assignAll(<ToastItem>[
      ...kept,
      ToastItem(id: id, text: text, kind: kind, onUndo: onUndo),
    ]);
    _timers[id] = Timer(lifetime, () => dismiss(id));
    return id;
  }

  void dismiss(int id) {
    _timers.remove(id)?.cancel();
    toasts.removeWhere((t) => t.id == id);
  }

  /// Runs the undo callback and removes the toast.
  void undo(int id) {
    final item = toasts.firstWhereOrNull((t) => t.id == id);
    item?.onUndo?.call();
    dismiss(id);
  }

  @override
  void onClose() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    super.onClose();
  }
}
