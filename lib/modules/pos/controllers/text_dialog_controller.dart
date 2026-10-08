import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../shared/controllers/overlay_controller.dart';
import '../../shell/controllers/settings_controller.dart';
import 'cart_controller.dart';
import 'cart_meta_controller.dart';

/// "Rename counter" and "Add order note": one text field preloaded with the
/// counter name or the cart note when the dialog opens (`setTextValue` before
/// `open`).
class TextDialogController extends GetxController {
  TextDialogController({
    required this.overlay,
    required this.settings,
    required this.cart,
    required this.meta,
  });

  static const String counterId = 'counter';
  static const String noteId = 'note';

  final OverlayController overlay;
  final SettingsController settings;
  final CartController cart;
  final CartMetaController meta;

  final TextEditingController text = TextEditingController();
  final FocusNode focus = FocusNode(debugLabel: 'text-dialog');

  /// `disabled={modal === "counter" && !textValue.trim()}`.
  final RxBool canSave = true.obs;

  Worker? _openWatcher;

  bool get isCounter => overlay.modal.value == counterId;

  @override
  void onInit() {
    super.onInit();
    text.addListener(_refresh);
    _openWatcher = ever<String?>(overlay.modal, (id) {
      if (id == counterId) {
        text.text = settings.settings.value.counter;
      } else if (id == noteId) {
        text.text = cart.cart.value.note;
      }
      _refresh();
    });
  }

  void _refresh() => canSave.value = !isCounter || text.text.trim().isNotEmpty;

  @override
  void onClose() {
    _openWatcher?.dispose();
    text.dispose();
    focus.dispose();
    super.onClose();
  }

  /// "Save": the counter is stored trimmed, the note as typed.
  void save() {
    if (!canSave.value) return;
    if (isCounter) {
      settings.setCounter(text.text.trim());
    } else {
      meta.setNote(text.text);
    }
    overlay.close();
  }
}
