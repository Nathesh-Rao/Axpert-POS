import '../../../core/services/packaging/packaging_service.dart';
import '../../../core/services/pricing/qty.dart';

import '../../../features/products/domain/entities/product.dart';
import '../models/cart.dart';
import '../models/cart_line.dart';
import '../models/held_bill.dart';
import '../../../core/utils/epoch_time.dart';

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
  HeldBill hold(Cart cart, DateTime now) =>
      HeldBill(ref: refFor(now), time: EpochTime.nowIso(now), cart: cart);

  /// Re-reads every line's product, clamps the quantity to the current stock
  /// and drops lines at zero. The stock is the base units of the product
  /// shared by all its lines (in order, DEC-154). A missing product crashes
  /// the prototype (`!` on `undefined`); here its line is dropped and
  /// reported (DEC-003).
  RecallOutcome recall(HeldBill bill, Product? Function(int id) productById) {
    final lines = <CartLine>[];
    final missing = <int>[];
    final used = <int, int>{};
    for (final line in bill.cart.lines) {
      final product = productById(line.product.id);
      if (product == null) {
        missing.add(line.product.id);
        continue;
      }
      final factor = line.packaging?.quantityBaseMilli ?? 1000;
      final left = product.stockQty.milli - (used[product.id] ?? 0);
      final room = Qty(
        const PackagingService().maxPackagesMilli(
          left,
          factor,
          whole: line.qty.milli % 1000 == 0,
        ),
      );
      final qty = line.qty < room ? line.qty : room;
      if (qty > Qty.zero) {
        final next = line.copyWith(product: product, qty: qty);
        used[product.id] = (used[product.id] ?? 0) + next.baseQty.milli;
        lines.add(next);
      }
    }
    return RecallOutcome(
      cart: bill.cart.copyWith(lines: lines),
      missingProducts: missing,
    );
  }
}
