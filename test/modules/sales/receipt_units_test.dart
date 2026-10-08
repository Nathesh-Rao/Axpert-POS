// Receipt document, date format, shortcut help and the print/share mocks
// (plain Dart; VM and Chrome).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/constants/en_app_strings.dart';
import 'package:pos_application/core/services/print_service.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/receipt_share_service.dart';
import 'package:pos_application/core/shortcuts/app_shortcuts.dart';
import 'package:pos_application/core/shortcuts/shortcut_help.dart';
import 'package:pos_application/core/utils/date_format.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/products/models/product.dart';
import 'package:pos_application/modules/sales/models/sale.dart';
import 'package:pos_application/modules/sales/services/receipt_builder.dart';

Money _inr(int minor) => Money(minor, CurrencyRegistry.inr);

Product _product(int id, String name) => Product(
  id: id,
  name: name,
  code: 'C$id',
  barcode: 'B$id',
  price: _inr(2000),
  category: 'c',
  sub: 's',
  stock: 10,
  gst: const Bp(500),
  image: -1,
  favourite: false,
);

Sale _sale({String mode = 'Cash'}) => Sale(
  number: 'AX000007',
  date: '2026-10-08T11:16:04.000Z',
  store: 'Maison Galaxy',
  customer: 'Ananya Sharma',
  cart: Cart(
    lines: <CartLine>[
      CartLine(
        product: _product(1, 'Lays Classic 52g'),
        qty: const Qty(1500),
        price: _inr(2000),
        discount: const Bp(1000),
      ),
      CartLine.of(_product(2, 'Pepsi 500ml')),
    ],
  ),
  totals: SaleTotals(
    items: 2,
    qty: const Qty(2500),
    value: _inr(4700),
    subtotal: _inr(4700),
    discount: _inr(300),
    tax: _inr(220),
    points: _inr(0),
    total: _inr(4620),
  ),
  mode: mode,
  tendered: _inr(5000),
  change: _inr(380),
  returned: const <int, Qty>{},
);

void main() {
  test('the builder copies the sale and computes only the line totals', () {
    final doc = ReceiptBuilder.fromSale(_sale());
    expect(doc.number, 'AX000007');
    expect(doc.store, 'Maison Galaxy');
    expect(doc.cashier, 'MGTCASH3');
    expect(doc.customer, 'Ananya Sharma');
    expect(doc.mode, 'Cash');
    expect(doc.subtotal, _inr(4700));
    expect(doc.discount, _inr(300));
    expect(doc.points, _inr(0));
    expect(doc.tax, _inr(220));
    expect(doc.total, _inr(4620));
    expect(doc.change, _inr(380));
    expect(doc.lines.map((l) => l.name), <String>[
      'Lays Classic 52g',
      'Pepsi 500ml',
    ]);
    // 1.5 x 20.00 less 10 % = 27.00; 1 x 20.00 = 20.00.
    expect(doc.lines[0].qty, const Qty(1500));
    expect(doc.lines[0].total, _inr(2700));
    expect(doc.lines[1].total, _inr(2000));
  });

  test('a draft keeps its Unpaid mode', () {
    expect(ReceiptBuilder.fromSale(_sale(mode: 'Unpaid')).mode, 'Unpaid');
  });

  test('en-GB date with a comma for the receipt', () {
    final t = DateTime(2026, 10, 7, 16, 57, 8);
    expect(DateFormatter.dateTimeComma(t), '07/10/2026, 16:57:08');
    expect(DateFormatter.dateTime(t), '07/10/2026 16:57:08');
  });

  test('every shortcut the help lists exists', () {
    final bound = AppShortcuts.bindings.keys.toList();
    bool has(ShortcutActivator a) {
      final key = a as SingleActivator;
      return bound.whereType<SingleActivator>().any(
        (b) =>
            b.trigger == key.trigger &&
            b.control == key.control &&
            b.meta == key.meta,
      );
    }

    expect(ShortcutHelp.entries, hasLength(9));
    for (final entry in ShortcutHelp.entries) {
      for (final key in entry.keys) {
        expect(
          has(key),
          isTrue,
          reason: '${entry.text(const EnAppStrings())} $key',
        );
      }
    }
    // Ctrl and Cmd both focus the search (the row names the platform's one).
    expect(ShortcutHelp.entries.first.keys, hasLength(2));
  });

  test('help labels are platform aware', () {
    final s = const EnAppStrings();
    String label(int i, TargetPlatform p) =>
        ShortcutHelp.entries[i].label(s, p);
    expect(label(0, TargetPlatform.macOS), '⌘K');
    expect(label(0, TargetPlatform.windows), 'Ctrl+K');
    expect(label(0, TargetPlatform.android), 'Ctrl+K');
    expect(
      <String>[for (var i = 1; i < 9; i++) label(i, TargetPlatform.windows)],
      <String>['Enter', 'F2', 'F3', 'F4', 'F5', 'F6', 'Delete', 'Esc'],
    );
    expect(
      <String>[for (final e in ShortcutHelp.entries) e.text(s)],
      <String>[
        'Focus barcode search',
        'Add scanned product',
        'Cash payment',
        'Card payment',
        'Hold bill',
        'Recall bill',
        'Apply discount',
        'Remove selected line',
        'Close dialog',
      ],
    );
  });

  test('the mocks record what they are given', () async {
    final doc = ReceiptBuilder.fromSale(_sale());
    final print = RecordingPrintService();
    await print.printReceipt(doc);
    expect(print.printed, <Object>[doc]);
    final share = RecordingReceiptShareService();
    await share.sendEmail(doc);
    await share.sendWhatsApp(doc);
    expect(share.emailed, <Object>[doc]);
    expect(share.whatsApped, <Object>[doc]);
  });
}
