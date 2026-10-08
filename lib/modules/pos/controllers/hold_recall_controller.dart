import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/controllers/clock_controller.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/controllers/search_field_controller.dart';
import '../../../shared/controllers/toast_controller.dart';
import '../../products/controllers/products_controller.dart';
import '../models/held_bill.dart';
import '../services/hold_recall_service.dart';
import 'cart_controller.dart';
import 'held_bills_controller.dart';

/// Hold (F4) and recall (F5): the prototype's `hold()`, `recall()` and the
/// "active cart" conflict (`recallPending`). The held list itself lives in
/// [HeldBillsController].
class HoldRecallController extends GetxController {
  HoldRecallController({
    required this.cart,
    required this.held,
    required this.products,
    required this.toasts,
    required this.search,
    required this.overlay,
    required this.clock,
    this.service = const HoldRecallService(),
  });

  final CartController cart;
  final HeldBillsController held;
  final ProductsController products;
  final ToastController toasts;
  final SearchFieldController search;
  final OverlayController overlay;
  final ClockController clock;
  final HoldRecallService service;

  /// The bill waiting for "Replace current" / "Hold & recall".
  final Rxn<HeldBill> pending = Rxn<HeldBill>();

  Worker? _closeWatcher;

  AppStrings get _s => AppStrings.current;

  @override
  void onInit() {
    super.onInit();
    // The prototype's `close()` also clears `recallPending`.
    _closeWatcher = ever<String?>(overlay.modal, (id) {
      if (id == null) pending.value = null;
    });
  }

  @override
  void onClose() {
    _closeWatcher?.dispose();
    super.onClose();
  }

  /// F5 and the Recall tile.
  void openRecall() => overlay.open('recall');

  /// F4 and the Hold tile.
  void hold() {
    if (!cart.active.value) {
      toasts.show(_s.toastAddItemsBeforeHold(), kind: ToastKind.info);
      return;
    }
    held.add(service.hold(cart.cart.value, clock.current));
    cart.clear();
    toasts.show(_s.toastBillHeld());
    search.refocus();
  }

  /// A click on a held bill: recall it, or ask first when a cart is active.
  void pick(HeldBill bill) {
    if (cart.active.value) {
      pending.value = bill;
    } else {
      recall(bill);
    }
  }

  void replaceCurrent() => recall(pending.value!);

  void holdAndRecall() => recall(pending.value!, holdCurrent: true);

  void recall(HeldBill bill, {bool holdCurrent = false}) {
    if (holdCurrent && cart.active.value) hold();
    final outcome = service.recall(bill, products.byId);
    cart.replace(outcome.cart);
    held.remove(bill.ref);
    overlay.close();
    toasts.show(_s.toastBillRecalled(bill.ref));
  }
}
