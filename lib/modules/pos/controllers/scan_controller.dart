import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/controllers/search_field_controller.dart';
import '../../../shared/controllers/toast_controller.dart';
import '../../products/controllers/products_controller.dart';
import 'cart_actions_controller.dart';

/// `scanProduct` of the prototype (shared by the top-bar search and the scan
/// simulator) and the simulator dialog's state.
class ScanController extends GetxController {
  ScanController({
    required this.products,
    required this.actions,
    required this.toasts,
    required this.search,
    required this.overlay,
    Random? random,
  }) : _random = random ?? Random();

  final ProductsController products;
  final CartActionsController actions;
  final ToastController toasts;
  final SearchFieldController search;
  final OverlayController overlay;
  final Random _random;

  final TextEditingController text = TextEditingController();
  final FocusNode focus = FocusNode(debugLabel: 'scan');

  /// "Simulate scan" is disabled while the text is empty.
  final RxBool hasText = false.obs;

  Worker? _openWatcher;

  AppStrings get _s => AppStrings.current;

  @override
  void onInit() {
    super.onInit();
    text.addListener(() => hasText.value = text.text.isNotEmpty);
    // `open()` resets the scan text.
    _openWatcher = ever<String?>(overlay.modal, (id) {
      if (id == 'scan') text.clear();
    });
  }

  @override
  void onClose() {
    _openWatcher?.dispose();
    text.dispose();
    focus.dispose();
    super.onClose();
  }

  /// Adds the product with that barcode or code (trimmed, code
  /// case-insensitive); a miss shows the error toast and clears the search.
  void scanProduct(String value) {
    final product = products.byScan(value);
    if (product != null) {
      actions.add(product);
    } else {
      toasts.show(
        _s.toastProductNotFoundForBarcode(value),
        kind: ToastKind.error,
      );
      search.text.clear();
      search.refocus();
    }
  }

  /// Enter in the simulator input, and "Simulate scan".
  void submit() {
    scanProduct(text.text);
    overlay.close();
  }

  /// "Scan random product": a random product with stock; nothing when none.
  void scanRandom() {
    final available = <int>[
      for (var i = 0; i < products.products.length; i++)
        if (products.products[i].stock > 0) i,
    ];
    if (available.isEmpty) return;
    final index = available[_random.nextInt(available.length)];
    actions.add(products.products[index]);
    overlay.close();
  }
}
