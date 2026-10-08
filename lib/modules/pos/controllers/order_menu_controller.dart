import 'package:get/get.dart';

import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../shared/controllers/clock_controller.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../sales/models/sale.dart';
import '../../shell/controllers/settings_controller.dart';
import '../services/checkout_service.dart';
import 'cart_controller.dart';
import 'cart_meta_controller.dart';

/// The "..." order menu: Rename counter, Add note, Print draft. Dialog ids
/// match the prototype's `modal` names.
class OrderMenuController extends GetxController {
  OrderMenuController({
    required this.cart,
    required this.meta,
    required this.settings,
    required this.clock,
    required this.overlay,
  });

  final CartController cart;
  final CartMetaController meta;
  final SettingsController settings;
  final ClockController clock;
  final OverlayController overlay;

  void renameCounter() => overlay.open('counter');

  void addNote() => overlay.open('note');

  /// Opens the receipt for an unpaid draft of the current cart.
  void printDraft() => overlay.open('receipt', payload: draftSale());

  /// The prototype's draft: number `DRAFT`, mode `Unpaid`, nothing tendered.
  Sale draftSale() {
    final totals = cart.totals.value;
    final zero = Money(0, totals.total.currency);
    return Sale(
      number: 'DRAFT',
      date: clock.now.value.toUtc().toIso8601String(),
      store: settings.settings.value.store,
      customer: meta.customer.name,
      cart: cart.cart.value,
      totals: SaleTotals(
        items: totals.items,
        qty: totals.qty,
        value: totals.value,
        subtotal: totals.subtotal,
        discount: totals.discount,
        tax: totals.tax,
        points: totals.points,
        total: totals.total,
      ),
      mode: SaleMode.unpaid,
      tendered: zero,
      change: zero,
      returned: const <int, Qty>{},
    );
  }
}
