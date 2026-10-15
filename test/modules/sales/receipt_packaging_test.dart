// DEC-154: how a line sold in a packaging prints: "2.000 Carton" in the qty
// cell and "1 Carton of 24 @ 960.00" under the name, before the offer text.
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/packaging/packaging_label.dart';
import 'package:pos_application/core/services/packaging/packaging_ref.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/print/receipt_print_model.dart';
import 'package:pos_application/core/utils/qty_formatter.dart';
import 'package:pos_application/features/products/domain/entities/product.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/pos/models/line_key.dart';
import 'package:pos_application/modules/sales/models/sale.dart';
import 'package:pos_application/modules/sales/services/receipt_builder.dart';

Money _inr(int minor) => Money(minor, CurrencyRegistry.inr);

final Product _cola = Product(
  id: 1,
  name: 'Cola',
  code: 'C1',
  barcode: 'B1',
  price: _inr(4000),
  category: 'Drinks',
  sub: 'Soft',
  stock: 100,
  gst: const Bp(0),
  image: -1,
  favourite: false,
);

const _carton = PackagingRef(
  id: 'ctn',
  unitName: 'Carton',
  quantityBaseMilli: 24000,
);

Sale _sale(List<CartLine> lines) => Sale(
  number: 'AX000001',
  date: '2026-10-08T11:16:04.000Z',
  store: 'S',
  customer: 'W',
  cart: Cart(lines: lines),
  totals: SaleTotals(
    items: lines.length,
    qty: Qty.units(3),
    value: _inr(200000),
    subtotal: _inr(200000),
    discount: _inr(0),
    tax: _inr(0),
    points: _inr(0),
    total: _inr(200000),
  ),
  mode: 'Cash',
  tendered: _inr(200000),
  change: _inr(0),
  returned: const <LineKey, Qty>{},
);

void main() {
  test('a packaging named with its size is not sized twice', () {
    expect(PackagingLabel.sized('Carton', '24'), 'Carton of 24');
    expect(PackagingLabel.sized('Carton of 24', '24'), 'Carton of 24');
  });

  test('a packaged line carries the unit and the pack detail', () {
    final carton = CartLine(
      product: _cola,
      qty: Qty.units(2),
      price: _inr(96000),
      discount: Bp.zero,
      packaging: _carton,
    );
    final doc = ReceiptBuilder.fromSale(_sale(<CartLine>[carton]));
    final line = doc.lines.single;
    expect(line.unitName, 'Carton');
    expect(line.note, '1 Carton of 24 @ ₹960.00');
    expect(line.total, _inr(192000));
    expect(
      QtyFormatter.fixed3WithUnit(line.qty, line.unitName),
      '2.000 Carton',
    );
  });

  test('the pack detail comes first, the offer text second', () {
    final carton = CartLine(
      product: _cola,
      qty: Qty.units(2),
      price: _inr(96000),
      discount: const Bp(5000),
      packaging: _carton,
      offer: const LineOffer(
        kind: 'promotion',
        name: 'Buy 1 Get 1',
        savingMinor: 96000,
        discountBp: 5000,
      ),
    );
    final note = ReceiptBuilder.fromSale(
      _sale(<CartLine>[carton]),
    ).lines.single.note!;
    expect(note.split('\n').first, '1 Carton of 24 @ ₹960.00');
    expect(note.split('\n').length, 2);
    expect(note, contains('Buy 1 Get 1'));
  });

  test('a base-unit line prints exactly as before', () {
    final piece = CartLine(
      product: _cola,
      qty: Qty.units(3),
      price: _inr(4000),
      discount: Bp.zero,
    );
    final doc = ReceiptBuilder.fromSale(_sale(<CartLine>[piece]));
    final line = doc.lines.single;
    expect(line.unitName, isNull);
    expect(line.note, isNull);
    expect(QtyFormatter.fixed3WithUnit(line.qty, line.unitName), '3.000');
  });

  test('the paper receipt shows the unit in the qty text', () {
    final carton = CartLine(
      product: _cola,
      qty: Qty.units(2),
      price: _inr(96000),
      discount: Bp.zero,
      packaging: _carton,
    );
    final doc = ReceiptBuilder.fromSale(_sale(<CartLine>[carton]));
    final item = ReceiptPrintModel.fromDocument(
      doc,
    ).rows.whereType<PrintItem>().single;
    expect(item.qty, '2.000 Carton');
    expect(item.note, '1 Carton of 24 @ ₹960.00');
  });
}
