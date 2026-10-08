// RefundService: lookup, checks, amount, applied sale and restock units
// (plain Dart; VM).
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/products/models/product.dart';
import 'package:pos_application/modules/returns/models/refund_request.dart';
import 'package:pos_application/modules/returns/services/refund_service.dart';
import 'package:pos_application/modules/sales/models/sale.dart';

import '../../support/sale_fixtures.dart';

Money _inr(int minor) => Money(minor, CurrencyRegistry.inr);

Product _product(int id, String name) => Product(
  id: id,
  name: name,
  code: 'C$id',
  barcode: 'B$id',
  price: _inr(4000),
  category: 'c',
  sub: 's',
  stock: 10,
  gst: const Bp(1800),
  image: -1,
  favourite: false,
);

/// 2 x 40.00 and 1.5 x 20.00: value 110.00, total 129.80 (18 % tax).
Sale _sale({Map<int, Qty> returned = const <int, Qty>{}}) => testSale(
  number: 'AX000007',
  at: DateTime(2026, 10, 8),
  customer: 'Ananya Sharma',
  totalMinor: 12980,
  valueMinor: 11000,
  returned: returned,
  cart: Cart(
    lines: <CartLine>[
      CartLine(
        product: _product(1, 'Cola'),
        qty: const Qty(2000),
        price: _inr(4000),
        discount: Bp.zero,
      ),
      CartLine(
        product: _product(2, 'Chips'),
        qty: const Qty(1500),
        price: _inr(2000),
        discount: const Bp(1000),
      ),
    ],
  ),
);

void main() {
  test('find is trimmed, case-insensitive and exact; the first match wins', () {
    final sales = <Sale>[
      testSale(number: 'AX000001', at: DateTime(2026, 10, 8)),
      _sale(),
      testSale(number: 'ax000007', at: DateTime(2026, 10, 8)),
    ];
    expect(RefundService.find(sales, ' ax000007 ')?.customer, 'Ananya Sharma');
    expect(RefundService.find(sales, 'AX00000'), isNull);
    expect(RefundService.find(sales, ''), isNull);
    expect(RefundService.find(sales, '   '), isNull);
  });

  test('available is sold minus returned', () {
    final sale = _sale(returned: const <int, Qty>{2: Qty(500)});
    expect(RefundService.available(sale, sale.cart.lines[0]), const Qty(2000));
    expect(RefundService.available(sale, sale.cart.lines[1]), const Qty(1000));
  });

  test('checks run in the prototype order', () {
    final sale = _sale(returned: const <int, Qty>{1: Qty(1500)});
    expect(
      RefundService.check(sale, const <int, Qty>{}),
      RefundCheck.noSelection,
    );
    expect(
      RefundService.check(sale, const <int, Qty>{1: Qty.zero}),
      RefundCheck.noSelection,
    );
    // 0.5 left of the first line: 0.501 exceeds, 0.5 does not.
    expect(
      RefundService.check(sale, const <int, Qty>{1: Qty(501)}),
      RefundCheck.exceeds,
    );
    expect(
      RefundService.check(sale, const <int, Qty>{1: Qty(500)}),
      RefundCheck.ok,
    );
    // an exceeding entry fails even next to a valid one
    expect(
      RefundService.check(sale, const <int, Qty>{1: Qty(500), 2: Qty(1501)}),
      RefundCheck.exceeds,
    );
    // a product that is not on the bill has nothing left
    expect(
      RefundService.check(sale, const <int, Qty>{9: Qty(1)}),
      RefundCheck.exceeds,
    );
  });

  test(
    'the amount is the gross share of the sale total (line discount ignored)',
    () {
      final sale = _sale();
      // 1 x 40.00 of 110.00 value: 129.80 * 40 / 110 = 47.2
      expect(
        RefundService.quote(sale, const <int, Qty>{1: Qty(1000)}),
        _inr(4720),
      );
      // 1.5 x 20.00 = 30.00 (its 10 % line discount is not in the share):
      // 129.80 * 30 / 110 = 35.4 - only the share, not what the line cost.
      expect(
        RefundService.quote(sale, const <int, Qty>{2: Qty(1500)}),
        _inr(3540),
      );
      // both lines in full return the whole total
      expect(
        RefundService.quote(sale, const <int, Qty>{1: Qty(2000), 2: Qty(1500)}),
        _inr(12980),
      );
      // zero entries and zero-value sales
      expect(RefundService.quote(sale, const <int, Qty>{}), _inr(0));
      final free = testSale(
        number: 'AX1',
        at: DateTime(2026, 10, 8),
        totalMinor: 0,
        valueMinor: 0,
        cart: _sale().cart,
      );
      expect(
        RefundService.quote(free, const <int, Qty>{1: Qty(1000)}),
        _inr(0),
      );
    },
  );

  test('applyReturned adds the typed quantities to returned', () {
    final sale = _sale(returned: const <int, Qty>{1: Qty(1000)});
    final next = RefundService.applyReturned(sale, const <int, Qty>{
      1: Qty(500),
      2: Qty(250),
      3: Qty.zero,
    });
    expect(next.returned, const <int, Qty>{1: Qty(1500), 2: Qty(250)});
    expect(sale.returned, const <int, Qty>{1: Qty(1000)}, reason: 'immutable');
    expect(next.number, sale.number);
    expect(next.totals.total, sale.totals.total);
  });

  test('restock rounds a fractional quantity up to whole units', () {
    expect(
      RefundService.restockUnits(const <int, Qty>{
        1: Qty(1000),
        2: Qty(1500),
        3: Qty(1),
        4: Qty.zero,
      }),
      const <int, int>{1: 1, 2: 2, 3: 1},
    );
  });

  test('refund request round-trips through JSON', () {
    const request = RefundRequest(
      saleNumber: 'AX000007',
      entries: <int, Qty>{1: Qty(1500), 2: Qty(250)},
    );
    final again = RefundRequest.fromJson(request.toJson());
    expect(again.saleNumber, 'AX000007');
    expect(again.entries, request.entries);
  });
}
