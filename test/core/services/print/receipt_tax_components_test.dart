// Receipt for 1, 2 and 3 tax components, the snapshot saved with a sale, and a
// long label on 80 mm paper.
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/pricing/tax_components.dart';
import 'package:pos_application/core/services/pricing/tax_split.dart';
import 'package:pos_application/core/services/print/receipt_pdf_builder.dart';
import 'package:pos_application/core/services/print/receipt_print_model.dart';
import 'package:pos_application/features/products/domain/entities/product.dart';
import 'package:pos_application/features/session/domain/entities/session_entities.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/pos/models/line_key.dart';
import 'package:pos_application/modules/sales/models/sale.dart';
import 'package:pos_application/modules/sales/services/receipt_builder.dart';

import '../../../support/test_tax.dart';

const _inr = CurrencyRegistry.inr;

Money _m(int minor) => Money(minor, _inr);

Sale _sale({List<TaxPart> parts = const <TaxPart>[]}) {
  final product = Product(
    id: 1,
    name: 'Cola',
    code: 'C1',
    barcode: 'B1',
    price: _m(10000),
    category: 'c',
    sub: 's',
    stock: 10,
    gst: const Bp(2100),
    image: -1,
    favourite: false,
  );
  return Sale(
    number: 'AX000001',
    date: '2026-10-08T11:16:04.000Z',
    store: 'Shop',
    customer: 'Walk-in Customer',
    cart: Cart(
      lines: [
        CartLine(
          product: product,
          qty: const Qty(1000),
          price: _m(10000),
          discount: Bp.zero,
        ),
      ],
    ),
    totals: SaleTotals(
      items: 1,
      qty: const Qty(1000),
      value: _m(10000),
      subtotal: _m(10000),
      discount: _m(0),
      tax: _m(2100),
      points: _m(0),
      total: _m(12100),
    ),
    mode: 'Cash',
    tendered: _m(12100),
    change: _m(0),
    returned: <LineKey, Qty>{},
    taxParts: parts,
  );
}

TaxRegimeInfo _regime(String label, List<TaxComponent> comps) => TaxRegimeInfo(
  region: 'XX',
  label: '',
  inclusive: false,
  slabs: [
    TaxSlabInfo.of(id: 'a', name: label, isDefault: true, components: comps),
  ],
);

List<String> _tax(ReceiptPrintModel model) => [
  for (final r in model.rows)
    if (r is PrintColumns &&
        r.label != 'Subtotal' &&
        r.label != 'Discount' &&
        r.label != 'Total' &&
        r.label != 'Payment' &&
        r.label != 'Change' &&
        !r.label.startsWith('Points') &&
        !r.label.startsWith('Reward'))
      '${r.label}|${r.value}|${r.wrapLabel}',
];

void main() {
  test('one component: the tax row alone', () {
    final regime = _regime('VAT 21%', const [
      TaxComponent(label: 'VAT', rateBp: 2100),
    ]);
    final doc = ReceiptBuilder.fromSale(_sale(), regime: regime);
    expect(doc.taxLabel, 'VAT');
    expect(doc.taxParts, isEmpty);
  });

  test('two components: today\'s CGST and SGST rows', () {
    final doc = ReceiptBuilder.fromSale(_sale(), regime: testIndiaRegime);
    expect(doc.taxLabel, 'GST');
    expect([for (final p in doc.taxParts) p.label], ['CGST', 'SGST']);
    expect([for (final p in doc.taxParts) p.amount.minor], [1050, 1050]);
  });

  test('three components from the current setup (an older sale)', () {
    final regime = _regime('3', const [
      TaxComponent(label: 'VAT', rateBp: 1600),
      TaxComponent(label: 'Levy', rateBp: 300),
      TaxComponent(label: 'Service charge', rateBp: 200),
    ]);
    final doc = ReceiptBuilder.fromSale(_sale(), regime: regime);
    expect(doc.taxLabel, 'Tax');
    expect(
      [for (final p in doc.taxParts) p.label],
      ['VAT', 'Levy', 'Service charge'],
    );
    expect(
      doc.taxParts.map((p) => p.amount.minor).reduce((a, b) => a + b),
      2100,
    );
  });

  test('the lines saved with the sale win over the current setup', () {
    final saved = [TaxPart('Old A', _m(1000)), TaxPart('Old B', _m(1100))];
    final doc = ReceiptBuilder.fromSale(
      _sale(parts: saved),
      regime: testIndiaRegime,
    );
    expect([for (final p in doc.taxParts) p.label], ['Old A', 'Old B']);
  });

  test('a sale keeps its tax lines through JSON', () {
    final sale = _sale(parts: [TaxPart('A', _m(1)), TaxPart('B', _m(2))]);
    final back = Sale.fromJson(sale.toJson());
    expect([for (final p in back.taxParts) p.label], ['A', 'B']);
    expect([for (final p in back.taxParts) p.amount.minor], [1, 2]);
    // No tax lines: the JSON is exactly what it was before.
    expect(_sale().toJson().containsKey('taxParts'), isFalse);
  });

  test('print model: heading and 3 rows, a long label is marked to wrap', () {
    final regime = _regime('x', const [
      TaxComponent(label: 'VAT', rateBp: 1600),
      TaxComponent(label: 'Municipal environment levy 2026', rateBp: 300),
      TaxComponent(label: 'Service charge', rateBp: 200),
    ]);
    final doc = ReceiptBuilder.fromSale(_sale(), regime: regime);
    final rows = _tax(ReceiptPrintModel.fromDocument(doc));
    expect(rows.where((r) => r.endsWith('|true')), hasLength(1));
    expect(
      rows.firstWhere((r) => r.endsWith('|true')),
      startsWith('Municipal environment levy 2026|'),
    );
    expect(rows.where((r) => r.endsWith('|false')), hasLength(3));
  });

  test('the 80 mm PDF builds with a long wrapped label', () async {
    const model = ReceiptPrintModel(<PrintRow>[
      PrintColumns(
        'Municipal environment levy and tourism contribution',
        '₹3.00',
        wrapLabel: true,
      ),
      PrintColumns('Total', '₹100.00'),
    ]);
    final bytes = await ReceiptPdfBuilder((asset) async {
      final data = await File(asset).readAsBytes();
      return ByteData.sublistView(data);
    }).build(model, paperMm: 80);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
