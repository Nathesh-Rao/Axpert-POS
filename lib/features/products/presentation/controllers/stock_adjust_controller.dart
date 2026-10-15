import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/pricing/qty.dart';
import '../../../../core/utils/decimal_input.dart';
import '../../../../core/utils/qty_formatter.dart';
import '../../../../shared/controllers/overlay_controller.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_admin_entities.dart';
import '../stock_text.dart';
import 'product_admin_controller.dart';
import 'product_form_controller.dart';

/// One packaging level of the counted-quantity entry.
class CountLevel {
  CountLevel({required this.name, required this.quantityBaseMilli});

  final String name;
  final int quantityBaseMilli;
  final TextEditingController count = TextEditingController();
}

/// "Adjust stock" (DEC-152): the counted quantity, a reason and a note become
/// one ledger movement through [ProductAdminController.adjustStock].
class StockAdjustController extends GetxController {
  StockAdjustController({
    required this.admin,
    required this.overlay,
    required this.product,
  });

  final ProductAdminController admin;
  final OverlayController overlay;
  final Product product;

  final TextEditingController base = TextEditingController();
  final TextEditingController note = TextEditingController();
  final List<CountLevel> levels = <CountLevel>[];
  final Rx<AdjustmentReason> reason = AdjustmentReason.countCorrection.obs;
  final RxBool loading = true.obs;
  final RxBool saving = false.obs;
  final RxString error = ''.obs;
  final RxInt tick = 0.obs;

  String _uuid = '';
  String baseUnitName = '';
  int currentMilli = 0;

  List<({String name, int quantityBaseMilli})> get _levels => [
    for (final l in levels)
      (name: l.name, quantityBaseMilli: l.quantityBaseMilli),
  ];

  String get currentText =>
      stockText(AppStrings.current, currentMilli, _levels, baseUnitName);

  Future<void> load() async {
    final d = await admin.repository.detail(product.id);
    if (d != null) {
      _uuid = d.uuid;
      currentMilli = d.balanceMilli;
      baseUnitName =
          (await admin.repository.stockViews())[product.id]?.baseUnitName ?? '';
      for (final p in d.packagings) {
        if (p.enabled) {
          levels.add(
            CountLevel(name: p.name, quantityBaseMilli: p.quantityBaseMilli),
          );
        }
      }
    }
    for (final c in [base, note, ...levels.map((l) => l.count)]) {
      c.addListener(() => tick.value++);
    }
    // Start from the current quantity in base units.
    base.text = QtyFormatter.compact(Qty(currentMilli));
    loading.value = false;
  }

  int? get _countedMilli {
    var total = 0;
    final text = base.text.trim();
    if (text.isNotEmpty) {
      final v = DecimalInput.tryScaled(text, 3);
      if (v == null || v < 0) return null;
      total += v;
    }
    for (final l in levels) {
      final t = l.count.text.trim();
      if (t.isEmpty) continue;
      final n = int.tryParse(t);
      if (n == null || n < 0) return null;
      total += n * l.quantityBaseMilli;
    }
    return total;
  }

  /// "Change: -5 Piece" under the entry, or null while it cannot be read.
  String? changeText() {
    tick.value; // ignore: unnecessary_statements
    final counted = _countedMilli;
    if (counted == null) return null;
    final s = AppStrings.current;
    final delta = counted - currentMilli;
    final text = stockText(s, delta.abs(), const [], baseUnitName);
    return s.adjustStockChange(delta < 0 ? '-$text' : '+$text');
  }

  Future<bool> submit() async {
    if (saving.value || loading.value) return false;
    final s = AppStrings.current;
    final counted = _countedMilli;
    if (counted == null) {
      error.value = s.productErrOpening();
      return false;
    }
    final delta = counted - currentMilli;
    if (delta == 0) {
      error.value = s.adjustErrNoChange();
      return false;
    }
    if (reason.value == AdjustmentReason.other && note.text.trim().isEmpty) {
      error.value = s.adjustErrReason();
      return false;
    }
    error.value = '';
    saving.value = true;
    try {
      final ok = await admin.adjustStock(
        uuid: _uuid,
        deltaMilli: delta,
        reason: reason.value,
        note: note.text.trim(),
      );
      if (ok) back();
      return ok;
    } on AdjustmentBlockedException catch (e) {
      error.value = s.adjustErrBlocked(
        stockText(s, e.availableMilli, _levels, baseUnitName),
      );
      return false;
    } finally {
      saving.value = false;
    }
  }

  /// Back to the product form (it stays open under this dialog's turn).
  void back() {
    if (Get.isRegistered<ProductFormController>()) {
      Get.find<ProductFormController>().refreshStock();
      overlay.open(ProductAdminController.formDialog);
    } else {
      overlay.close();
    }
  }

  @override
  void onClose() {
    base.dispose();
    note.dispose();
    for (final l in levels) {
      l.count.dispose();
    }
    super.onClose();
  }
}
