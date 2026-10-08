import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/controllers/toast_controller.dart';
import '../../products/controllers/products_controller.dart';
import '../../products/models/product.dart';

/// The Price Check dialog: looks a product up on every keystroke by exact
/// barcode or case-insensitive code (not trimmed); nothing is added.
class PriceCheckController extends GetxController {
  PriceCheckController({
    required this.products,
    required this.toasts,
    required this.overlay,
  });

  final ProductsController products;
  final ToastController toasts;
  final OverlayController overlay;

  final TextEditingController text = TextEditingController();
  final FocusNode focus = FocusNode(debugLabel: 'price-check');

  final Rxn<Product> product = Rxn<Product>();
  final RxString query = ''.obs;

  Worker? _openWatcher;

  @override
  void onInit() {
    super.onInit();
    // `open()` resets the text and the result.
    _openWatcher = ever<String?>(overlay.modal, (id) {
      if (id == 'priceCheck') {
        text.clear();
        product.value = null;
        query.value = '';
      }
    });
  }

  @override
  void onClose() {
    _openWatcher?.dispose();
    text.dispose();
    focus.dispose();
    super.onClose();
  }

  void onChanged(String value) {
    query.value = value;
    product.value = products.byExact(value);
  }

  /// Enter without a match: the error toast (nothing happens on a match).
  void onSubmit() {
    if (product.value == null) {
      toasts.show(
        AppStrings.current.toastProductNotFound(),
        kind: ToastKind.error,
      );
    }
  }
}
