import 'package:get/get.dart';

import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../shared/controllers/clock_controller.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../sales/models/sale.dart';
import '../../../features/session/presentation/controllers/active_session.dart';
import '../services/checkout_service.dart';
import 'cart_controller.dart';
import 'cart_meta_controller.dart';
import '../../../core/utils/epoch_time.dart';

/// The "..." order menu: Rename counter, Add note, Print draft. Dialog ids
/// match the prototype's `modal` names.
class OrderMenuController extends GetxController {
  OrderMenuController({
    required this.cart,
    required this.meta,
    required this.session,
    required this.clock,
    required this.overlay,
  });

  final CartController cart;
  final CartMetaController meta;
  final ActiveSession session;
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
      date: EpochTime.nowIso(clock.current),
      store: session.store.value?.name ?? '',
      cashier: session.displayName.isEmpty ? null : session.displayName,
      customer: meta.customer.name,
      cart: cart.cartAsSold,
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
