import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/services/pricing/pricing_models.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../models/cart.dart';
import '../services/discount_rules.dart';
import 'cart_controller.dart';

/// The bill discount drawer (`discountForm` state of the prototype): the
/// draft type, number and reason, applied or removed on the cart.
class DiscountFormController extends GetxController {
  DiscountFormController({required this.cart, required this.overlay});

  final CartController cart;
  final OverlayController overlay;

  final Rx<BillDiscountType> type = BillDiscountType.percent.obs;
  final TextEditingController value = TextEditingController();
  final TextEditingController reason = TextEditingController();
  final FocusNode valueFocus = FocusNode(debugLabel: 'discount-value');

  @override
  void onClose() {
    value.dispose();
    reason.dispose();
    valueFocus.dispose();
    super.onClose();
  }

  /// F6 and the Discount tile: `openDiscount()` copies the cart's discount
  /// into the form and opens the drawer.
  void open() {
    final current = cart.cart.value;
    type.value = current.billDiscount.type;
    value.text = DiscountRules.textOf(
      current.billDiscount,
      cart.totals.value.subtotal.currency,
    );
    reason.text = current.reason;
    overlay.open('discount');
  }

  /// Segmented buttons: only the type changes (the number is left as typed,
  /// KG-122).
  void setType(BillDiscountType next) => type.value = next;

  /// Every keystroke: the number is clamped to its range as the prototype
  /// does (`max(0, min(max, Number(text)))`).
  void onValueChanged(String text) {
    final shown = DiscountRules.shown(
      type.value,
      text,
      subtotal: cart.totals.value.subtotal,
    );
    if (shown != text) {
      value.value = TextEditingValue(
        text: shown,
        selection: TextSelection.collapsed(offset: shown.length),
      );
    }
  }

  /// "Apply discount".
  void apply() {
    final subtotal = cart.totals.value.subtotal;
    final scaled = DiscountRules.clampScaledUnbounded(
      type.value,
      value.text,
      currency: subtotal.currency,
    );
    cart.patch(
      (c) => c.copyWith(
        billDiscount: DiscountRules.toDiscount(
          type.value,
          scaled,
          subtotal.currency,
        ),
        reason: reason.text,
      ),
    );
    overlay.close();
  }

  /// "Remove": no discount and no reason.
  void remove() {
    cart.patch(
      (Cart c) =>
          c.copyWith(billDiscount: const BillDiscount.none(), reason: ''),
    );
    overlay.close();
  }
}
