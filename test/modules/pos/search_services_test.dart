// The product search and customer rules of the prototype (plain Dart).
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/customers/services/customer_rules.dart';
import 'package:pos_application/modules/pos/services/product_search.dart';
import 'package:pos_application/modules/products/models/product.dart';

Product _p(int id, String name, String code) => Product(
  id: id,
  name: name,
  code: code,
  barcode: '890$id',
  price: const Money(1000, CurrencyRegistry.inr),
  category: 'c',
  sub: 's',
  stock: 5,
  gst: const Bp(500),
  image: -1,
  favourite: false,
);

String _key(Product p) => '${p.name} ${p.code}'.toLowerCase();

void main() {
  group('ProductSearch', () {
    final list = <Product>[
      _p(1, 'Coca Cola 500ml', 'BDV001'),
      _p(2, 'Pepsi 500ml', 'BDV002'),
      _p(3, 'Cola Zero', 'BDV010'),
      for (var i = 4; i < 20; i++) _p(i, 'Cola Item $i', 'X$i'),
    ];

    test('digits-only and empty text never match', () {
      expect(ProductSearch.isDigitsOnly('8901234567890'), isTrue);
      expect(ProductSearch.isDigitsOnly('12a'), isFalse);
      expect(ProductSearch.isDigitsOnly(''), isFalse);
      expect(ProductSearch.matches(list, _key, ''), isEmpty);
      expect(ProductSearch.matches(list, _key, '8901'), isEmpty);
    });

    test('case-insensitive on name and code, list order, at most 6', () {
      final m = ProductSearch.matches(list, _key, 'COLA');
      expect(m.map((p) => p.id), <int>[1, 3, 4, 5, 6, 7]);
      expect(ProductSearch.matches(list, _key, 'bdv00').map((p) => p.id), <int>[
        1,
        2,
      ]);
      // The key joins name and code with a space.
      expect(ProductSearch.matches(list, _key, '500ml bdv').length, 2);
    });

    test('stops scanning at the limit', () {
      var calls = 0;
      String counting(Product p) {
        calls++;
        return _key(p);
      }

      ProductSearch.matches(list, counting, 'cola');
      expect(calls, lessThan(list.length));
      calls = 0;
      expect(ProductSearch.matches(list, counting, 'zzz'), isEmpty);
      expect(calls, list.length);
    });
  });

  group('CustomerRules', () {
    const walk = Customer(
      id: 'walk',
      name: 'Walk-in Customer',
      phone: '',
      email: '',
      member: '',
      points: 0,
    );
    const ananya = Customer(
      id: '1',
      name: 'Ananya Rao',
      phone: '+91 98450 11111',
      email: 'a@x.in',
      member: 'MG10001',
      points: 120,
    );

    test('filter on name, phone and member, walk-in included', () {
      final all = <Customer>[walk, ananya];
      List<String> ids(String q) => CustomerRules.filter(
        all,
        CustomerRules.searchKey,
        q,
      ).map((c) => c.id).toList();
      expect(ids(''), <String>['walk', '1']);
      expect(ids('ANANYA'), <String>['1']);
      expect(ids('98450'), <String>['1']);
      expect(ids('mg100'), <String>['1']);
      expect(ids('walk'), <String>['walk']);
      expect(ids('zzz'), isEmpty);
    });

    test('validation: name, phone and email edges', () {
      bool ok(String n, String p, [String e = '']) =>
          CustomerRules.isValid(name: n, phone: p, email: e);
      expect(ok('A', '1234567'), isTrue);
      expect(ok('  ', '1234567'), isFalse);
      expect(ok('A', '123456'), isFalse); // 6 characters
      expect(ok('A', '123456789012345'), isTrue); // 15
      expect(ok('A', '1234567890123456'), isFalse); // 16
      expect(ok('A', '+91 98450-11111'), isTrue);
      expect(ok('A', '98450x11111'), isFalse);
      expect(ok('A', '1234567', 'a@b.co'), isTrue);
      expect(ok('A', '1234567', 'a@b'), isFalse);
      expect(ok('A', '1234567', 'a b@c.d'), isFalse);
    });

    test('create: clock id, MG plus five digits, untrimmed name', () {
      final now = DateTime.fromMillisecondsSinceEpoch(1790000123456);
      final c = CustomerRules.create(
        name: ' Ravi ',
        phone: '9845011111',
        email: '',
        now: now,
      );
      expect(c.id, '1790000123456');
      expect(c.member, 'MG23456');
      expect(c.name, ' Ravi ');
      expect(c.points, 0);
    });
  });
}
