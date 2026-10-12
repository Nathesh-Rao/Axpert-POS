import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/features/products/domain/entities/product.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/pos/models/held_bill.dart';

Product heldProduct(int id, {int stock = 10, int priceMinor = 4000}) => Product(
  id: id,
  name: 'P$id',
  code: 'C$id',
  barcode: 'B$id',
  price: Money(priceMinor, CurrencyRegistry.inr),
  category: 'c',
  sub: 's',
  stock: stock,
  gst: const Bp(1800),
  image: -1,
  favourite: false,
);

/// A held bill with one line of product [productId] (quantity [qtyMilli]).
HeldBill heldBill(
  String ref, {
  int productId = 1,
  int qtyMilli = 2000,
  String time = '2026-10-12T10:00:00.000Z',
  String note = '',
}) {
  final p = heldProduct(productId);
  return HeldBill(
    ref: ref,
    time: time,
    cart: Cart(
      lines: <CartLine>[
        CartLine(
          product: p,
          qty: Qty(qtyMilli),
          price: p.price,
          discount: Bp.zero,
        ),
      ],
      note: note,
    ),
  );
}
