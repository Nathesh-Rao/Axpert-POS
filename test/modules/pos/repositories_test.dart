import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/mock/large_dataset.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/mock/seed_products.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/customers/repository/mock_customer_repository.dart';
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/held_bill.dart';
import 'package:pos_application/modules/pos/repository/mock_cart_repository.dart';
import 'package:pos_application/modules/pos/repository/mock_held_bill_repository.dart';
import 'package:pos_application/modules/products/repository/mock_product_repository.dart';
import 'package:pos_application/modules/sales/repository/mock_sale_repository.dart';

void main() {
  setUp(() => MockDelay.provider = () => Duration.zero);

  test('products seed on first run and persist changes', () async {
    final store = InMemoryLocalStore();
    final repo = MockProductRepository(store);
    final first = await repo.load();
    expect(first.length, 20);
    expect(await store.has(StorageKeys.products), isTrue);
    await repo.save(
      <dynamic>[
        for (final p in first) p.id == 3 ? p.copyWith(favourite: true) : p,
      ].cast(),
    );
    final again = await MockProductRepository(store).load();
    expect(again[3].favourite, isTrue);
  });

  test('forceSeed replaces stored data (debug large dataset)', () async {
    final store = InMemoryLocalStore();
    await MockProductRepository(store).load();
    final big = LargeDataset.products(500);
    final loaded = await MockProductRepository(
      store,
      seed: big,
      forceSeed: true,
    ).load();
    expect(loaded.length, 500);
  });

  test('large dataset is off by default', () {
    expect(LargeDataset.enabled, isFalse);
    final big = LargeDataset.products();
    expect(big.length, 10000);
    expect(big.map((p) => p.barcode).toSet().length, 10000);
  });

  test('customers seed and reload', () async {
    final store = InMemoryLocalStore();
    final list = await MockCustomerRepository(store).load();
    expect(list.length, 4);
    expect((await MockCustomerRepository(store).load()).length, 4);
  });

  test('cart draft, held bills and sales round trip', () async {
    final store = InMemoryLocalStore();
    final carts = MockCartRepository(store);
    expect((await carts.load()).lines, isEmpty);
    final cart = Cart.empty.addItem(SeedProducts.products()[0]);
    await carts.save(cart);
    expect((await MockCartRepository(store).load()).lines, cart.lines);

    final held = MockHeldBillRepository(store);
    expect(await held.load(), isEmpty);
    await held.save(<HeldBill>[HeldBill(ref: '000001', time: 't', cart: cart)]);
    expect((await held.load()).single.ref, '000001');

    expect(await MockSaleRepository(store).load(), isEmpty);
  });

  test('corrupt cart json falls back to the empty cart', () async {
    final store = InMemoryLocalStore();
    await store.write(StorageKeys.cart, <String, dynamic>{'lines': 5});
    expect((await MockCartRepository(store).load()).lines, isEmpty);
  });
}
