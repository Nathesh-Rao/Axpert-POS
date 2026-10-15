// The print-only receipt layout (80 mm, light only): the print model drawn the
// way the PDF lays it out. Not compared with React; a regression test of the
// printed content and row structure (the PDF itself cannot be rasterised in a
// VM test).
@Tags(<String>['golden'])
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/print/receipt_print_model.dart';
import 'package:pos_application/features/products/domain/entities/product.dart';
import 'package:pos_application/features/session/domain/entities/session_entities.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/sales/models/sale.dart';
import 'package:pos_application/modules/sales/services/receipt_builder.dart';

import '../support/print_preview.dart';
import '../support/test_tax.dart';
import 'harness.dart';

Money _m(int minor) => Money(minor, CurrencyRegistry.inr);

Product _p(int id, String name, int price) => Product(
  id: id,
  name: name,
  code: 'C$id',
  barcode: 'B$id',
  price: _m(price),
  category: 'c',
  sub: 's',
  stock: 10,
  gst: const Bp(1800),
  image: -1,
  favourite: false,
);

void main() {
  useTolerantGoldens();
  final skip = fontsSkipReason();
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (skip.isEmpty) await loadTestFonts();
  });

  testWidgets(
    '${skip.isEmpty ? '' : '[$skip] '}Print-only receipt, 80 mm',
    (tester) async {
      final sale = Sale(
        number: 'AX000042',
        cashier: 'Chitra Cashier',
        date: '2026-10-07T16:57:08',
        store: 'Axpert Mart - Ozone',
        customer: 'Walk-in Customer',
        cart: Cart(
          lines: [
            CartLine(
              product: _p(1, 'Oreo Biscuit 120g', 3500),
              qty: const Qty(2000),
              price: _m(3500),
              discount: const Bp(5000),
              offer: const LineOffer(
                kind: 'promotion',
                name: 'Oreo Buy 1 Get 1',
                savingMinor: 3500,
                discountBp: 5000,
              ),
            ),
            CartLine(
              product: _p(2, 'Coca Cola 500ml', 4000),
              qty: const Qty(1000),
              price: _m(3200),
              discount: Bp.zero,
            ),
            CartLine(
              product: _p(3, 'Dairy Milk 40g', 5000),
              qty: const Qty(1000),
              price: _m(0),
              discount: Bp.zero,
              offer: const LineOffer(
                kind: 'gift_tier',
                name: 'Spend 500 get Dairy Milk free',
                savingMinor: 5000,
                isGift: true,
              ),
            ),
          ],
        ),
        totals: SaleTotals(
          items: 3,
          qty: const Qty(4000),
          value: _m(12000),
          subtotal: _m(6700),
          discount: _m(5300),
          tax: _m(1207),
          points: _m(0),
          total: _m(7907),
        ),
        mode: 'Cash',
        tendered: _m(8000),
        change: _m(93),
        returned: const <int, Qty>{},
      );
      final doc = ReceiptBuilder.fromSale(
        sale,
        store: const StoreInfo(
          id: 's',
          name: 'x',
          currencyCode: 'INR',
          address: '12 MG Road, Bengaluru 560001',
          phone: '+91 80 5550 0101',
          taxId: 'GSTIN 29DEMO1234F1Z5',
          receiptHeader: 'Demo store - not a real invoice',
          receiptFooter: 'Thank you for shopping at Axpert Mart!',
        ),
        regime: testIndiaRegime,
      );
      tester.view
        ..devicePixelRatio = 2
        ..physicalSize = const Size(340 * 2, 820 * 2);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Material(
            color: const Color(0xFFE5E7EB),
            child: Align(
              alignment: Alignment.topCenter,
              child: RepaintBoundary(
                key: const Key('print-receipt'),
                child: PrintPreview(model: ReceiptPrintModel.fromDocument(doc)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const Key('print-receipt')),
        matchesGoldenFile('goldens/print_receipt_80mm_light.png'),
      );
    },
    skip: skip.isNotEmpty,
  );
}
