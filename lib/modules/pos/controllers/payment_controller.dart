import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/config/checkout_policy.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/database/persist_outcome.dart';
import '../../../core/identifiers/uuid_generator.dart';
import '../../../core/identifiers/uuid_v4_generator.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/qty.dart';
import '../../../core/utils/decimal_input.dart';
import '../../../core/utils/decimal_text.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/bindings/startup_timeline.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/controllers/search_field_controller.dart';
import '../../../shared/controllers/toast_controller.dart';
import '../../customers/controllers/customers_controller.dart';
import '../../../features/payment/data/services/mock_payment_service.dart';
import '../../../features/payment/domain/entities/payment_method.dart';
import '../../../features/payment/domain/entities/payment_request.dart';
import '../../../features/payment/domain/entities/payment_result.dart';
import '../../../features/payment/domain/services/payment_service.dart';
import '../../../features/products/presentation/controllers/products_controller.dart';
import '../../sales/controllers/sales_controller.dart';
import '../../../features/session/presentation/controllers/active_session.dart';
import '../models/cart.dart';
import '../models/payment_state.dart';
import '../repository/checkout_repository.dart';
import '../services/checkout_service.dart';
import 'cart_controller.dart';
import 'cart_meta_controller.dart';

/// Payment panel state and the checkout flow (prototype `payment()` and
/// `complete()`). Permanent: the Bill Summary and F2/F3 exist on every page.
class PaymentController extends GetxController {
  PaymentController({
    required this.cart,
    required this.meta,
    required this.products,
    required this.customers,
    required this.sales,
    required this.session,
    required this.toasts,
    required this.overlay,
    required this.search,
    required this.checkout,
    this.service = const CheckoutService(),
    this.payments = const MockPaymentService(),
    UuidGenerator? uuid,
    this.terminalDelay = const Duration(seconds: 2),
    DateTime Function()? now,
    bool? commitBeforeReceipt,
  }) : _uuid = uuid ?? UuidV4Generator(),
       _now = now ?? DateTime.now,
       _commitBeforeReceipt =
           commitBeforeReceipt ?? CheckoutPolicy.commitBeforeReceipt;

  static const Duration tenderedFocusDelay = Duration(milliseconds: 40);

  final CartController cart;
  final CartMetaController meta;
  final ProductsController products;
  final CustomersController customers;
  final SalesController sales;
  final ActiveSession session;
  final ToastController toasts;
  final OverlayController overlay;
  final SearchFieldController search;
  final CheckoutService service;

  /// Persists the checkout (one Drift transaction, or the independent saves).
  final CheckoutRepository checkout;

  /// The payment boundary (DEC-123): cash and card sales go through it,
  /// credit sales do not.
  final PaymentService payments;
  final UuidGenerator _uuid;
  final Duration terminalDelay;
  final DateTime Function() _now;
  final bool _commitBeforeReceipt;

  final Rx<PaymentMode> mode = PaymentMode.cash.obs;
  final Rx<TerminalState> terminal = TerminalState.waiting.obs;
  final RxBool decline = false.obs;
  final RxString tenderedValue = ''.obs;
  final TextEditingController tendered = TextEditingController();
  final FocusNode tenderedFocus = FocusNode(debugLabel: 'tendered');

  /// True while a payment is being processed: a second Complete is ignored.
  bool _processing = false;

  Timer? _terminalTimer;
  Timer? _focusTimer;

  AppStrings get _s => AppStrings.current;

  @override
  void onInit() {
    super.onInit();
    tendered.addListener(() => tenderedValue.value = tendered.text);
    // The terminal effect: card mode + active cart + waiting.
    everAll(<RxInterface>[mode, terminal, decline, cart.active], (_) {
      _syncTerminalTimer();
    });
    ever(cart.active, (bool active) {
      if (!active) _reset();
    });
  }

  void _reset() {
    mode.value = PaymentMode.cash;
    tendered.text = '';
    terminal.value = TerminalState.waiting;
    decline.value = false;
  }

  void _syncTerminalTimer() {
    _terminalTimer?.cancel();
    _terminalTimer = null;
    if (mode.value == PaymentMode.card &&
        cart.active.value &&
        terminal.value == TerminalState.waiting) {
      _terminalTimer = Timer(terminalDelay, () {
        terminal.value = decline.value
            ? TerminalState.declined
            : TerminalState.approved;
      });
    }
  }

  // ---- derived state ----

  Cart get _cart => cart.cart.value;
  Money get total => cart.totals.value.total;
  bool get isCredit => _cart.saleType == SaleType.credit;

  /// `cart.lines.length > 0 && (Cash || customer != walk)`.
  bool get canPay => _cart.isActive && (!isCredit || !meta.customer.isWalkIn);

  /// Typed tendered amount; null when empty or not a number.
  Money? get tenderedMoney {
    final minor = DecimalInput.tryScaled(
      tenderedValue.value,
      total.currency.exponent,
    );
    return minor == null ? null : Money(minor, total.currency);
  }

  Money get _zero => Money(0, total.currency);

  /// `Number(tendered) - total` (empty counts as 0): can be negative.
  Money get changeDue => (tenderedMoney ?? _zero) - total;

  bool get isShort => (tenderedMoney ?? _zero) < total;

  /// Cash Complete button and Enter: a tendered amount that covers the total.
  bool get canCompleteCash {
    if (!canPay) return false;
    if (isCredit) return true;
    final t = tenderedMoney;
    return tenderedValue.value.isNotEmpty && t != null && t >= total;
  }

  bool get canCompleteCard =>
      canPay && terminal.value == TerminalState.approved;

  // ---- actions ----

  /// Quick amount button text (`String(amount)`).
  void setTenderedMoney(Money amount) {
    tendered.text = DecimalText.scaled(amount.minor, amount.currency.exponent);
  }

  void setQuickAmount(int? whole) {
    if (whole == null) {
      setTenderedMoney(total);
    } else {
      setTenderedMoney(Money(whole * _unit, total.currency));
    }
  }

  int get _unit {
    var unit = 1;
    for (var i = 0; i < total.currency.exponent; i++) {
      unit *= 10;
    }
    return unit;
  }

  void setDecline(bool value) => decline.value = value;

  void retry() {
    decline.value = false;
    terminal.value = TerminalState.waiting;
  }

  /// Cash / Card buttons and F2 / F3 (prototype `payment(mode)`).
  void payment(PaymentMode requested) {
    if (!cart.isActive) return;
    if (isCredit) {
      final customer = meta.customer;
      if (customer.isWalkIn) {
        toasts.show(_s.toastCreditNeedsCustomer(), kind: ToastKind.warning);
        return;
      }
      overlay.openConfirm(
        _s.confirmSaveCredit(
          total: MoneyFormatter.format(total),
          customer: customer.name,
        ),
        () => _complete(SaleMode.credit, _zero),
      );
      return;
    }
    if (requested == PaymentMode.cash) {
      mode.value = PaymentMode.cash;
      _fixedTwo();
      _focusTimer?.cancel();
      _focusTimer = Timer(tenderedFocusDelay, tenderedFocus.requestFocus);
    } else {
      mode.value = PaymentMode.card;
      terminal.value = TerminalState.waiting;
      decline.value = false;
    }
  }

  /// `totals.total.toFixed(2)` for the cash text.
  void _fixedTwo() {
    final e = total.currency.exponent;
    final minor = total.minor.abs();
    final digits = minor.toString().padLeft(e + 1, '0');
    final cut = digits.length - e;
    tendered.text = e == 0
        ? digits
        : '${digits.substring(0, cut)}.${digits.substring(cut)}';
  }

  void completeCash() {
    if (!canCompleteCash) return;
    if (isCredit) {
      payment(PaymentMode.cash);
    } else {
      unawaited(_complete(SaleMode.cash, tenderedMoney!));
    }
  }

  /// Enter inside the tendered field.
  void submitTendered() {
    if (canPay && !isCredit && canCompleteCash) completeCash();
  }

  void completeCard() {
    if (!canCompleteCard) return;
    unawaited(_complete(SaleMode.card, total));
  }

  Future<void> _complete(String saleMode, Money amount) async {
    if (!cart.isActive || _processing) return;
    _processing = true;
    final allowNegative = session.store.value?.allowNegativeStock ?? false;
    final oversold =
        allowNegative &&
        cart.cartAsSold.lines.any(
          (l) => l.qty > (products.byId(l.product.id)?.stockQty ?? Qty.zero),
        );
    try {
      final result = service.complete(
        cart: cart.cartAsSold,
        totals: cart.totals.value,
        customer: meta.customer,
        stockOf: (id) => products.byId(id)?.stockQty ?? Qty.zero,
        salesCount: sales.sales.length,
        store: session.store.value?.name ?? '',
        cashier: session.displayName,
        now: _now(),
        mode: saleMode,
        tendered: amount,
        saleId: _uuid.generate(),
        allowNegativeStock: allowNegative,
      );
      switch (result) {
        case CheckoutStockChanged():
          toasts.show(_s.toastStockChanged(), kind: ToastKind.error);
        case CheckoutDone():
          // Credit sales are not paid at the till: no payment service call.
          PaymentResult? payment;
          if (saleMode != SaleMode.credit) {
            payment = await _pay(result, saleMode);
            if (payment == null) {
              toasts.show(_s.toastPaymentFailed(), kind: ToastKind.error);
              return;
            }
          }
          if (oversold) {
            toasts.show(_s.toastStockNegative(), kind: ToastKind.warning);
          }
          final receiptWatch = Stopwatch()..start();
          // Memory first (DEC-129): the user-visible effects do not wait for
          // the database. The three lists are persisted as one unit.
          sales.addInMemory(result.sale);
          products.applyStockDeltasInMemory(result.stockDeltas);
          customers.deductPointsInMemory(
            meta.customer.id,
            result.pointsDeducted,
          );
          final persisted = _persist(
            CheckoutCommit(
              sale: result.sale,
              payment: payment,
              salesAfter: sales.sales.toList(),
              productsAfter: products.products.toList(),
              customersAfter: customers.customers.toList(),
            ),
          );
          if (_commitBeforeReceipt) await persisted;
          cart.clear();
          search.refocus();
          overlay.open('receipt', payload: result.sale);
          toasts.show(
            saleMode == SaleMode.credit
                ? _s.toastSavedOnCredit()
                : _s.toastPaymentCompleted(),
          );
          StartupTimeline.logElapsed('checkout receipt', receiptWatch);
      }
    } finally {
      _processing = false;
    }
  }

  /// Persists the checkout; a fully failed save (neither Drift nor the
  /// LocalStore fallback) is the only case the user is told about.
  Future<PersistOutcome> _persist(CheckoutCommit commit) async {
    PersistOutcome outcome;
    try {
      outcome = await checkout.commit(commit);
    } on Object {
      outcome = PersistOutcome.failed;
    }
    if (outcome == PersistOutcome.failed) {
      toasts.show(_s.toastSaveFailed(), kind: ToastKind.error);
    }
    return outcome;
  }

  /// Asks the payment service for the amount due (`sale.totals.total`, for
  /// cash and card); tendered and change stay on the sale only. Returns the
  /// payment when it succeeded, else null.
  Future<PaymentResult?> _pay(CheckoutDone done, String saleMode) async {
    final outcome = await payments.process(
      PaymentRequest(
        paymentId: _uuid.generate(),
        saleId: done.sale.saleId!,
        amount: done.sale.totals.total,
        method: saleMode == SaleMode.card
            ? PaymentMethod.card
            : PaymentMethod.cash,
      ),
    );
    return outcome.fold(
      onSuccess: (payment) => payment.succeeded ? payment : null,
      onFailure: (_) => null,
    );
  }

  @override
  void onClose() {
    _terminalTimer?.cancel();
    _focusTimer?.cancel();
    tendered.dispose();
    tenderedFocus.dispose();
    super.onClose();
  }
}
