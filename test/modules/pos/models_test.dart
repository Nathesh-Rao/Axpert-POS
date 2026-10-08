import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/mock/seed_customers.dart';
import 'package:pos_application/core/mock/seed_products.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/pricing_models.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/utils/gst_json.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/pos/models/held_bill.dart';
import 'package:pos_application/modules/products/models/product.dart';
import 'package:pos_application/modules/sales/models/sale.dart';

Map<String, dynamic> _roundTrip(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  group('gst json', () {
    test('plain numbers parse to basis points without float math', () {
      expect(GstJson.parse(18), const Bp(1800));
      expect(GstJson.parse(5), const Bp(500));
      expect(GstJson.parse(12.5), const Bp(1250));
      expect(GstJson.parse(0.1), const Bp(10));
      expect(GstJson.parse('2.25'), const Bp(225));
    });

    test('whole percentages stay ints, fractions become decimals', () {
      expect(GstJson.toJson(const Bp(1800)), 18);
      expect(GstJson.toJson(const Bp(1250)), 12.5);
      expect(GstJson.toJson(const Bp(225)), 2.25);
    });
  });

  group('round trips', () {
    test('product', () {
      for (final p in SeedProducts.products()) {
        expect(Product.fromJson(_roundTrip(p.toJson())), p);
      }
      final odd = SeedProducts.products().first.copyWith(favourite: true);
      expect(odd.toJson()['gst'], 18);
    });

    test('customer', () {
      for (final c in SeedCustomers.customers) {
        expect(Customer.fromJson(_roundTrip(c.toJson())), c);
      }
    });

    test('cart with percent and flat bill discount', () {
      final products = SeedProducts.products();
      final lines = <CartLine>[
        CartLine(
          product: products[5],
          qty: const Qty(2500),
          price: const Money(1999, CurrencyRegistry.inr),
          discount: const Bp(1250),
        ),
        CartLine.of(products[0]),
      ];
      final percent = Cart(
        lines: lines,
        customer: '2',
        saleType: SaleType.credit,
        billDiscount: const BillDiscount.percent(Bp(500)),
        reason: 'promo',
        points: 40,
        note: 'gift',
      );
      final flat = percent.copyWith(
        billDiscount: const BillDiscount.flat(
          Money(12345, CurrencyRegistry.inr),
        ),
      );
      for (final cart in <Cart>[percent, flat]) {
        final back = Cart.fromJson(_roundTrip(cart.toJson()));
        expect(back.lines, cart.lines);
        expect(back.customer, cart.customer);
        expect(back.saleType, cart.saleType);
        expect(back.billDiscount.type, cart.billDiscount.type);
        expect(back.billDiscount.percent, cart.billDiscount.percent);
        expect(back.billDiscount.flat, cart.billDiscount.flat);
        expect(back.reason, 'promo');
        expect(back.points, 40);
        expect(back.note, 'gift');
      }
    });

    test('held bill and sale', () {
      final cart = Cart.empty.addItem(SeedProducts.products()[1]);
      final held = HeldBill(
        ref: '123456',
        time: '2026-10-08T10:00:00',
        cart: cart,
      );
      final back = HeldBill.fromJson(_roundTrip(held.toJson()));
      expect(back.ref, '123456');
      expect(back.cart.lines, cart.lines);

      Money money(int v) => Money(v, CurrencyRegistry.inr);
      final sale = Sale(
        number: 'S-1',
        date: '2026-10-08T10:00:00',
        store: 'MAISON GALAXY - OZONE',
        customer: 'Walk-in Customer',
        cart: cart,
        totals: SaleTotals(
          items: 1,
          qty: const Qty(1000),
          value: money(4000),
          subtotal: money(4000),
          discount: money(0),
          tax: money(480),
          points: money(0),
          total: money(4480),
        ),
        mode: 'Cash',
        tendered: money(5000),
        change: money(520),
        returned: <int, Qty>{1: const Qty(1000)},
      );
      final again = Sale.fromJson(_roundTrip(sale.toJson()));
      expect(again.number, 'S-1');
      expect(again.totals.total, money(4480));
      expect(again.tendered, money(5000));
      expect(again.returned, <int, Qty>{1: const Qty(1000)});
      expect(again.cart.lines, cart.lines);
    });
  });
}
