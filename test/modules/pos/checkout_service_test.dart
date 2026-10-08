// CheckoutService: the prototype's complete() as a plain Dart function.
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/pricing_models.dart';
import 'package:pos_application/core/services/pricing/pricing_service.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/services/checkout_service.dart';
import 'package:pos_application/modules/products/models/product.dart';

Money inr(int minor) => Money(minor, CurrencyRegistry.inr);

Product product(int id, {int stock = 10, int priceMinor = 2000}) => Product(
  id: id,
  name: 'P$id',
  code: 'C$id',
  barcode: 'B$id',
  price: inr(priceMinor),
  category: 'Snacks',
  sub: 'Chips',
  stock: stock,
  gst: const Bp(500),
  image: -1,
  favourite: false,
);

CartTotals totalsOf(Cart cart, {int points = 0}) =>
    const PricingService().calculate(
      CartInput(
        lines: <LineInput>[
          for (final l in cart.lines)
            LineInput(
              qty: l.qty,
              price: l.price,
              taxRate: l.product.gst,
              discount: l.discount,
            ),
        ],
        billDiscount: cart.billDiscount,
        pointsToRedeem: cart.points,
        availablePoints: points,
      ),
    );

const walk = Customer(
  id: Customer.walkInId,
  name: 'Walk-in Customer',
  phone: '',
  email: '',
  member: '',
  points: 0,
);

CheckoutResult run(
  Cart cart, {
  Customer customer = walk,
  int salesCount = 0,
  String mode = SaleMode.cash,
  Money? tendered,
  Qty Function(int)? stockOf,
}) => const CheckoutService().complete(
  cart: cart,
  totals: totalsOf(cart, points: customer.points),
  customer: customer,
  stockOf: stockOf ?? (id) => Qty.units(10),
  salesCount: salesCount,
  store: 'S',
  now: DateTime.utc(2026, 10, 8, 12),
  mode: mode,
  tendered: tendered ?? inr(5000),
);

void main() {
  final cart = Cart.empty.addItem(product(1));

  test('builds the sale: AX + 6 digits from the ledger length, change', () {
    final r = run(cart, salesCount: 41) as CheckoutDone;
    expect(r.sale.number, 'AX000042');
    expect(r.sale.totals.total, inr(2100));
    expect(r.sale.tendered, inr(5000));
    expect(r.sale.change, inr(2900));
    expect(r.sale.mode, 'Cash');
    expect(r.sale.customer, 'Walk-in Customer');
    expect(r.stockDeltas, <int, int>{1: 1});
    expect(r.pointsDeducted, 0);
  });

  test('change is zero for card and credit', () {
    for (final mode in <String>[SaleMode.card, SaleMode.credit]) {
      final r = run(cart, mode: mode) as CheckoutDone;
      expect(r.sale.change, inr(0));
    }
  });

  test('stock re-validation blocks a line above the live stock', () {
    final two = cart.setQty(1, Qty.units(3));
    expect(run(two, stockOf: (_) => Qty.units(2)), isA<CheckoutStockChanged>());
    expect(run(two, stockOf: (_) => Qty.units(3)), isA<CheckoutDone>());
  });

  test('redeemed points are deducted (whole points)', () {
    const member = Customer(
      id: '1',
      name: 'Ananya',
      phone: '',
      email: '',
      member: 'MG1',
      points: 250,
    );
    final withPoints = cart.copyWith(customer: '1', points: 5);
    final r = run(withPoints, customer: member) as CheckoutDone;
    expect(r.sale.totals.points, inr(500));
    expect(r.sale.totals.total, inr(1600));
    expect(r.pointsDeducted, 5);
  });

  test('fractional quantity rounds the stock delta up', () {
    final frac = cart.setQty(1, const Qty(1500));
    final r = run(frac) as CheckoutDone;
    expect(r.stockDeltas, <int, int>{1: 2});
  });
}
