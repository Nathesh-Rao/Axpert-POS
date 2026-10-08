import '../../../core/services/pricing/qty.dart';

import '../../products/models/product.dart';
import '../models/cart.dart';
import '../models/cart_line.dart';
import '../models/held_bill.dart';

/// What recalling a held bill gives: the rebuilt cart and the product ids of
/// the lines that could not be restored (product no longer exists).
class RecallOutcome {
  const RecallOutcome({required this.cart, required this.missingProducts});

  final Cart cart;
  final List<int> missingProducts;
}

/// The prototype's `hold()` and `recall()` rules as plain Dart (no GetX, no
/// Flutter): the held reference and the recalled cart.
class HoldRecallService {
  const HoldRecallService();

  /// `"H" + Date.now().toString().slice(-6)`: the last six digits of the
  /// epoch milliseconds.
  static String refFor(DateTime now) {
    final digits = now.millisecondsSinceEpoch.toString();
    final tail = digits.length > 6
        ? digits.substring(digits.length - 6)
        : digits;
    return 'H$tail';
  }

  /// `{ref, time: toISOString(), cart}`.
  HeldBill hold(Cart cart, DateTime now) => HeldBill(
    ref: refFor(now),
    time: now.toUtc().toIso8601String(),
    cart: cart,
  );

  /// Re-reads every line's product, clamps the quantity to the current stock
  /// and drops lines at zero. A missing product crashes the prototype
  /// (`!` on `undefined`); here its line is dropped and reported (DEC-003).
  RecallOutcome recall(HeldBill bill, Product? Function(int id) productById) {
    final lines = <CartLine>[];
    final missing = <int>[];
    for (final line in bill.cart.lines) {
      final product = productById(line.product.id);
      if (product == null) {
        missing.add(line.product.id);
        continue;
      }
      final qty = line.qty < product.stockQty ? line.qty : product.stockQty;
      if (qty > Qty.zero) lines.add(line.copyWith(product: product, qty: qty));
    }
    return RecallOutcome(
      cart: bill.cart.copyWith(lines: lines),
      missingProducts: missing,
    );
  }
}
