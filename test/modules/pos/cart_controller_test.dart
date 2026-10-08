import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/pricing_models.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/pricing/rational.dart';
import 'package:pos_application/modules/customers/controllers/customers_controller.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/customers/repository/customer_repository.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/cart_line.dart';
import 'package:pos_application/modules/pos/repository/mock_cart_repository.dart';
import 'package:pos_application/modules/products/models/product.dart';

import '../../fixtures/pricing_golden_data.g.dart';
import '../../support/pos_support.dart';
import '../../support/test_app.dart';

class _FixedCustomers implements CustomerRepository {
  _FixedCustomers(this._list);
  final List<Customer> _list;
  @override
  Future<List<Customer>> load() async => _list;
  @override
  Future<void> save(List<Customer> customers) async {}
}

const _inr = CurrencyRegistry.inr;

void main() {
  useTestApp();
  setUp(() => MockDelay.provider = () => Duration.zero);

  test(
    'totals equal the React golden vectors (through the controller)',
    () async {
      final vectors =
          ((jsonDecode(pricingGoldenJson) as Map)['vectors'] as List)
              .cast<Map<String, dynamic>>();
      final failures = <String>[];
      for (final v in vectors) {
        final available = int.parse(v['available'] as String);
        final customers = CustomersController(
          _FixedCustomers(<Customer>[
            Customer(
              id: 'c',
              name: 'c',
              phone: '',
              email: '',
              member: '',
              points: available,
            ),
          ]),
        );
        await customers.load();
        final controller = CartController(
          MockCartRepository(await _store()),
          customers,
        );
        final flat = v['discountType'] == 'flat';
        final bd = v['billDiscount'] as String;
        final lines = <CartLine>[
          for (final (i, l)
              in (v['lines'] as List).cast<Map<String, dynamic>>().indexed)
            CartLine(
              product: Product(
                id: i,
                name: 'p$i',
                code: 'c$i',
                barcode: 'b$i',
                price: Money.parse(l['price'] as String, _inr),
                category: 'x',
                sub: 'y',
                stock: 1000000,
                gst: Bp.parsePercent(l['gst'] as String),
                image: -1,
                favourite: false,
              ),
              qty: Qty.parse(l['qty'] as String),
              price: Money.parse(l['price'] as String, _inr),
              discount: Bp.parsePercent(l['discount'] as String),
            ),
        ];
        controller.replace(
          Cart(
            lines: lines,
            customer: 'c',
            billDiscount: flat
                ? BillDiscount.flat(Money.parse(bd, _inr))
                : BillDiscount.percent(Bp.parsePercent(bd)),
            points: int.parse(v['points'] as String),
          ),
        );
        final exp = (v['expected'] as Map).cast<String, dynamic>();
        final t = controller.totals.value;
        final id = v['id'] as String;
        expect(t.items, exp['items'], reason: id);
        expect(t.qty.milli, exp['qtyMilli'], reason: id);
        final fields = <String, (Money, Rational)>{
          'value': (t.value, t.exact.value),
          'discount': (t.discount, t.exact.discount),
          'tax': (t.tax, t.exact.tax),
          'points': (t.points, t.exact.points),
          'total': (t.total, t.exact.total),
        };
        fields.forEach((name, pair) {
          final want = Money.parse(exp[name] as String, _inr).minor;
          final (m, exact) = pair;
          if (m.minor == want) return;
          // Same rule as the S1 golden test: 1-unit miss at a tie only (KG-079).
          final isTie = exact.isTie && (m.minor - want).abs() == 1;
          if (!isTie) failures.add('$id.$name got ${m.minor} want $want');
        });
        await controller.flush();
      }
      expect(failures, isEmpty);
    },
  );

  test('every change is persisted, latest state wins', () async {
    final h = await PosHarness.boot();
    final p = h.products.byId(5)!;
    h.cart.addItem(p);
    h.cart.addItem(p);
    h.cart.setPrice(5, const Money(3000, _inr));
    await h.cart.flush();
    final json = await h.store.read(StorageKeys.cart) as Map<String, dynamic>;
    final saved = Cart.fromJson(json);
    expect(saved.lines.single.qty, Qty.units(2));
    expect(saved.lines.single.price.minor, 3000);
  });

  test('the draft is loaded on start', () async {
    final h = await PosHarness.boot();
    h.cart.addItem(h.products.byId(0)!);
    await h.cart.flush();
    Get.reset();
    final h2 = await PosHarness.boot(store: h.store);
    expect(h2.cart.cart.value.lines.single.product.id, 0);
    expect(h2.cart.totals.value.items, 1);
  });

  test('line listenable notifies only for the changed product', () async {
    final h = await PosHarness.boot();
    final a = h.products.byId(0)!;
    final b = h.products.byId(1)!;
    h.cart.addItem(a);
    var aCount = 0;
    var bCount = 0;
    h.cart.lineListenable(0).addListener(() => aCount++);
    h.cart.lineListenable(1).addListener(() => bCount++);
    h.cart.addItem(b);
    expect((aCount, bCount), (0, 1));
    h.cart.setQty(0, Qty.units(3));
    expect((aCount, bCount), (1, 1));
    h.cart.removeLine(1);
    expect((aCount, bCount), (1, 2));
    expect(h.cart.lineListenable(1).value, isNull);
  });

  test('products controller index maps', () async {
    final h = await PosHarness.boot();
    expect(h.products.byScan('8901234567895')?.name, 'Lays Classic 52g');
    expect(h.products.byScan(' chp001 ')?.id, 5);
    expect(h.products.byScan('nope'), isNull);
    expect(h.products.searchKey(h.products.byId(0)!), 'coca cola 500ml bdv001');
    await h.products.toggleFavourite(1);
    expect(h.products.byId(1)!.favourite, isTrue);
    await h.products.toggleFavourite(1);
    expect(h.products.byId(1)!.favourite, isFalse);
  });
}

Future<InMemoryLocalStore> _store() async => InMemoryLocalStore();
