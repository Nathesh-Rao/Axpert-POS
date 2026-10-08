import '../../../core/constants/storage_keys.dart';
import '../../../core/mock/mock_delay.dart';
import '../../../core/services/storage/local_store.dart';
import '../models/cart.dart';
import 'cart_repository.dart';

class MockCartRepository implements CartRepository {
  MockCartRepository(this._store);

  final LocalStore _store;

  @override
  Future<Cart> load() async {
    await MockDelay.wait();
    final json = await _store.read(StorageKeys.cart);
    if (json is! Map<String, dynamic>) return Cart.empty;
    try {
      return Cart.fromJson(json);
    } on Object {
      return Cart.empty;
    }
  }

  @override
  Future<void> save(Cart cart) async {
    await MockDelay.wait();
    await _store.write(StorageKeys.cart, cart.toJson());
  }
}
