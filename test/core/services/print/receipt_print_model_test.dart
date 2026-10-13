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
import 'package:pos_application/modules/sales/models/receipt_document.dart';
import 'package:pos_application/modules/sales/models/sale.dart';
import 'package:pos_application/modules/sales/services/receipt_builder.dart';

import '../../../support/test_tax.dart';

const _inr = CurrencyRegistry.inr;
const _ugx = CurrencyRegistry.ugx;

Product _product(int id, String name, int priceMinor, Money Function(int) m) =>
    Product(
      id: id,
      name: name,
      code: 'C$id',
      barcode: 'B$id',
      price: m(priceMinor),
      category: 'c',
      sub: 's',
      stock: 10,
      gst: const Bp(1800),
      image: -1,
      favourite: false,
    );

Sale _sale({
  required Money Function(int) m,
  required List<CartLine> lines,
  required int value,
  required int subtotal,
  required int discount,
  required int tax,
  required int total,
}) => Sale(
  number: 'AX000042',
  cashier: 'Chitra Cashier',
  date: '2026-10-08T11:16:04.000Z',
  store: 'Axpert Mart',
  customer: 'Walk-in Customer',
  cart: Cart(lines: lines),
  totals: SaleTotals(
    items: lines.length,
    qty: const Qty(1000),
    value: m(value),
    subtotal: m(subtotal),
    discount: m(discount),
    tax: m(tax),
    points: m(0),
    total: m(total),
  ),
  mode: 'Cash',
  tendered: m(total),
  change: m(0),
  returned: const <int, Qty>{},
);

const _store = StoreInfo(
  id: 's',
  name: 'Axpert Mart',
  currencyCode: 'INR',
  address: '12 MG Road',
  phone: '+91 80 5550 0101',
  taxId: 'GSTIN 29DEMO',
  receiptHeader: 'Demo store',
  receiptFooter: 'Come again!',
);

List<String> _texts(ReceiptPrintModel model) => [
  for (final r in model.rows)
    switch (r) {
      PrintText() => r.text,
      PrintColumns() => '${r.label}|${r.value}',
      PrintItem() => '${r.name}|${r.qty}|${r.total}|${r.note ?? ''}',
      PrintDivider() => '---',
    },
];

void main() {
  Money inr(int minor) => Money(minor, _inr);
  Money ugx(int minor) => Money(minor, _ugx);

  group('India (GST with CGST and SGST)', () {
    // 1 item at 100.00, 18 %: tax 18.00; odd case: tax 0.05 -> 2 + 3 paise.
    final sale = _sale(
      m: inr,
      lines: [
        CartLine(
          product: _product(1, 'Cola', 10000, inr),
          qty: const Qty(1000),
          price: inr(10000),
          discount: Bp.zero,
        ),
      ],
      value: 10000,
      subtotal: 10000,
      discount: 0,
      tax: 1801,
      total: 11801,
    );
    final doc = ReceiptBuilder.fromSale(
      sale,
      store: _store,
      regime: testIndiaRegime,
    );
    final texts = _texts(ReceiptPrintModel.fromDocument(doc));

    test('the header carries the store row', () {
      expect(texts.take(8), [
        'AXPERT POS',
        'Axpert Mart',
        '12 MG Road',
        '+91 80 5550 0101',
        'GSTIN 29DEMO',
        'Demo store',
        'Retail tax invoice',
        '---',
      ]);
    });

    test('the tax row and its split, odd paisa on the last part', () {
      expect(
        texts,
        containsAllInOrder(['GST|₹18.01', 'CGST|₹9.00', 'SGST|₹9.01']),
      );
    });

    test('item, total and the store footer', () {
      expect(texts, contains('Cola|1.000|₹100.00|'));
      expect(texts, contains('Total|₹118.01'));
      expect(texts.last, 'Come again!');
    });
  });

  group('VAT store (UGX)', () {
    final sale = _sale(
      m: ugx,
      lines: [
        CartLine(
          product: _product(2, 'Soda', 1800, ugx),
          qty: const Qty(1000),
          price: ugx(1800),
          discount: Bp.zero,
        ),
      ],
      value: 1800,
      subtotal: 1800,
      discount: 0,
      tax: 324,
      total: 2124,
    );
    final doc = ReceiptBuilder.fromSale(sale, regime: testVatRegime);
    final texts = _texts(ReceiptPrintModel.fromDocument(doc));

    test('one VAT line, no GST, CGST or SGST text anywhere', () {
      expect(texts, contains('VAT|USh 324'));
      expect(texts.where((t) => t.contains('GST')), isEmpty);
    });

    test('amounts have no decimals', () {
      expect(texts, contains('Soda|1.000|USh 1,800|'));
      expect(texts, contains('Total|USh 2,124'));
    });
  });

  test('a store without a regime prints no tax row', () {
    final sale = _sale(
      m: inr,
      lines: const [],
      value: 0,
      subtotal: 0,
      discount: 0,
      tax: 0,
      total: 0,
    );
    final texts = _texts(
      ReceiptPrintModel.fromDocument(ReceiptBuilder.fromSale(sale)),
    );
    expect(
      texts.any((t) => t.startsWith('GST') || t.startsWith('VAT')),
      isFalse,
    );
    expect(texts, containsAll(['Subtotal|₹0.00', 'Total|₹0.00']));
  });

  test('a free item prints at 0 with its offer note; a discount line shows '
      'its saving', () {
    final cart = Cart(
      lines: [
        CartLine(
          product: _product(3, 'Biscuit', 5000, inr),
          qty: const Qty(2000),
          price: inr(5000),
          discount: const Bp(5000),
          offer: const LineOffer(
            kind: 'promotion',
            name: 'Buy 1 Get 1',
            savingMinor: 5000,
            discountBp: 5000,
          ),
        ),
        CartLine(
          product: _product(4, 'Dairy Milk', 4000, inr),
          qty: const Qty(1000),
          price: inr(0),
          discount: Bp.zero,
          offer: const LineOffer(
            kind: 'gift_tier',
            name: 'Spend 500',
            savingMinor: 4000,
            isGift: true,
          ),
        ),
      ],
    );
    final sale = Sale(
      number: 'AX000043',
      cashier: 'C',
      date: '2026-10-08T11:16:04.000Z',
      store: 'Axpert Mart',
      customer: 'Walk-in Customer',
      cart: cart,
      totals: SaleTotals(
        items: 2,
        qty: const Qty(3000),
        value: inr(10000),
        subtotal: inr(5000),
        discount: inr(5000),
        tax: inr(900),
        points: inr(0),
        total: inr(5900),
      ),
      mode: 'Cash',
      tendered: inr(5900),
      change: inr(0),
      returned: const <int, Qty>{},
    );
    final items = ReceiptPrintModel.fromDocument(
      ReceiptBuilder.fromSale(sale, regime: testIndiaRegime),
    ).rows.whereType<PrintItem>().toList();
    expect(items, hasLength(2));
    expect(items[0].total, '₹50.00');
    expect(items[0].note, contains('Buy 1 Get 1'));
    expect(items[1].total, '₹0.00');
    expect(items[1].note, contains('Spend 500'));
  });

  test('the model is built from the document alone (no recomputation)', () {
    final doc = ReceiptDocument(
      number: 'X',
      date: DateTime(2026, 1, 2, 3, 4, 5),
      store: 'S',
      cashier: 'C',
      customer: 'K',
      lines: const [],
      subtotal: inr(1),
      discount: inr(2),
      points: inr(3),
      tax: inr(5),
      total: inr(7),
      mode: 'Card',
      change: inr(0),
      taxLabel: 'GST',
    );
    final texts = _texts(ReceiptPrintModel.fromDocument(doc));
    expect(
      texts,
      containsAll(['Subtotal|₹0.01', 'Discount|₹0.02', 'GST|₹0.05']),
    );
    expect(texts, contains('Payment|Card'));
  });
}
