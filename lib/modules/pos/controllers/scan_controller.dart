import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/controllers/search_field_controller.dart';
import '../../../shared/controllers/toast_controller.dart';
import '../../../features/products/presentation/controllers/products_controller.dart';
import '../../../core/utils/serial_queue.dart';
import '../../../features/products/domain/entities/packaging_entities.dart';
import '../../../features/products/domain/repositories/packaging_repositories.dart';
import 'cart_actions_controller.dart';
import 'packaging_catalog_controller.dart';
import 'pos_work_view_controller.dart';

/// `scanProduct` of the prototype (shared by the top-bar search and the scan
/// simulator) and the simulator dialog's state.
class ScanController extends GetxController {
  ScanController({
    required this.products,
    required this.actions,
    required this.toasts,
    required this.search,
    required this.overlay,
    this.barcodes,
    this.catalog,
    this.storeId,
    Random? random,
  }) : _random = random ?? Random();

  final ProductsController products;
  final CartActionsController actions;
  final ToastController toasts;
  final SearchFieldController search;
  final OverlayController overlay;

  /// Looks up pack and carton barcodes (DEC-154); null where unavailable
  /// (LocalStore and mock backends): then only the base barcode and the code
  /// of the product list are used.
  final BarcodeRepository? barcodes;
  final PackagingCatalogController? catalog;

  /// The store of the open session (barcodes are scoped per store).
  final String? Function()? storeId;
  final Random _random;

  /// Scans run strictly in order: a lookup that has to wait for the database
  /// never lets a later scan overtake it or add twice.
  final SerialQueue _queue = SerialQueue();
  int _pending = 0;

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
  ///
  /// A pack or carton barcode adds that packaging line (DEC-154). The lookup
  /// goes through [barcodes] when there is one; a base barcode or a code that
  /// the product list knows is added at once when no other scan is waiting.
  Future<void> scanProduct(String value) {
    final text = value.trim();
    if (barcodes == null) {
      _scanBase(value);
      return Future<void>.value();
    }
    if (_pending == 0) {
      final known = products.byScan(value);
      if (known != null && known.barcode == text) {
        // A base barcode cannot also be a pack barcode (unique index).
        _scanBase(value);
        return Future<void>.value();
      }
    }
    _pending++;
    return _queue.run(() async {
      try {
        await _scanLookup(value, text);
      } finally {
        _pending--;
      }
    });
  }

  Future<void> _scanLookup(String value, String text) async {
    BarcodeMatch? match;
    try {
      match = await barcodes!.findByBarcode(storeId?.call(), text);
    } on Object {
      match = null; // a failing lookup falls back to the product list
    }
    final packaging = match?.packaging;
    final product = match == null ? null : products.byId(match.productLegacyId);
    if (packaging != null && product != null) {
      final option = catalog?.optionForPackaging(product, packaging.id);
      if (option != null) {
        actions.add(product, packaging: option.packaging, price: option.price);
        _showCart();
        return;
      }
    }
    _scanBase(value);
  }

  void _scanBase(String value) {
    final product = products.byScan(value);
    if (product != null) {
      actions.add(product);
      _showCart();
    } else {
      toasts.show(
        _s.toastProductNotFoundForBarcode(value),
        kind: ToastKind.error,
      );
      search.text.clear();
      search.refocus();
    }
  }

  void _showCart() {
    if (Get.isRegistered<PosWorkViewController>()) {
      Get.find<PosWorkViewController>().showCart();
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
    _showCart();
    overlay.close();
  }
}
