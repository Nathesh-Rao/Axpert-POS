import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/services/pricing/basis_points.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/pricing_models.dart';
import '../../../core/services/pricing/pricing_service.dart';
import '../../../core/services/pricing/qty.dart';
import '../../customers/controllers/customers_controller.dart';
import '../../products/models/product.dart';
import '../models/cart.dart';
import '../models/cart_line.dart';
import '../repository/cart_repository.dart';

/// Permanent cart state. Applies the reducer rules, persists the draft after
/// every change (serialised, latest state wins) and computes the totals with
/// [PricingService] once per change, never in `build`.
class CartController extends GetxController {
  CartController(
    this._repository,
    this._customers, {
    PricingService pricing = const PricingService(),
  }) : _pricing = pricing;

  final CartRepository _repository;
  final CustomersController _customers;
  final PricingService _pricing;

  final Rx<Cart> cart = Cart.empty.obs;
  late final Rx<CartTotals> totals = _totalsOf(Cart.empty).obs;

  final Map<int, ValueNotifier<CartLine?>> _lineNotifiers =
      <int, ValueNotifier<CartLine?>>{};
  Future<void>? _saving;
  bool _dirty = false;

  bool get isActive => cart.value.isActive;

  Future<void> load() async {
    _apply(await _repository.load(), persist: false);
  }

  @override
  void onInit() {
    super.onInit();
    ever(_customers.customers, (_) => _recomputeTotals());
  }

  /// Notifies only when the line of [productId] changes (scoped rebuilds for
  /// product cards and cart rows).
  ValueListenable<CartLine?> lineListenable(int productId) =>
      _lineNotifiers.putIfAbsent(
        productId,
        () => ValueNotifier<CartLine?>(cart.value.lineOf(productId)),
      );

  CartLine? lineOf(int productId) => cart.value.lineOf(productId);

  // ---- reducer rules (no side effects; see CartActionsController) ----

  void addItem(Product product) => _set(cart.value.addItem(product));

  void setQty(int id, Qty qty) => _set(cart.value.setQty(id, qty));

  void setPrice(int id, Money price) => _set(cart.value.setPrice(id, price));

  void setLineDiscount(int id, Bp discount) =>
      _set(cart.value.setLineDiscount(id, discount));

  void removeLine(int id) => _set(cart.value.removeLine(id));

  void restoreLine(CartLine line) => _set(cart.value.restoreLine(line));

  void clear() => _set(Cart.empty);

  /// Replaces the whole cart (recall, S4).
  void replace(Cart next) => _set(next);

  void patch(Cart Function(Cart) change) => _set(change(cart.value));

  /// Waits until the pending save finished (tests, shutdown).
  Future<void> flush() async {
    while (_saving != null) {
      await _saving;
    }
  }

  void _set(Cart next) {
    if (identical(next, cart.value)) return;
    _apply(next, persist: true);
  }

  void _apply(Cart next, {required bool persist}) {
    final previous = cart.value;
    cart.value = next;
    _recomputeTotals();
    _notifyLines(previous, next);
    if (persist) _persist();
  }

  void _recomputeTotals() => totals.value = _totalsOf(cart.value);

  CartTotals _totalsOf(Cart value) {
    final customer = _customers.byIdOrFirst(value.customer);
    return _pricing.calculate(
      CartInput(
        lines: <LineInput>[
          for (final line in value.lines)
            LineInput(
              qty: line.qty,
              price: line.price,
              taxRate: line.product.gst,
              discount: line.discount,
            ),
        ],
        billDiscount: value.billDiscount,
        pointsToRedeem: value.points,
        availablePoints: customer?.points ?? 0,
      ),
    );
  }

  void _notifyLines(Cart before, Cart after) {
    if (_lineNotifiers.isEmpty) return;
    final ids = <int>{
      for (final l in before.lines) l.product.id,
      for (final l in after.lines) l.product.id,
    };
    for (final id in ids) {
      _lineNotifiers[id]?.value = after.lineOf(id);
    }
  }

  void _persist() {
    _dirty = true;
    _saving ??= _drain();
  }

  Future<void> _drain() async {
    try {
      while (_dirty) {
        _dirty = false;
        await _repository.save(cart.value);
      }
    } finally {
      _saving = null;
    }
  }

  @override
  void onClose() {
    for (final n in _lineNotifiers.values) {
      n.dispose();
    }
    _lineNotifiers.clear();
    super.onClose();
  }
}
