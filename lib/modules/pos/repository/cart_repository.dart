import '../models/cart.dart';

/// The cart draft (persisted on every change, as the prototype does).
abstract interface class CartRepository {
  Future<Cart> load();

  Future<void> save(Cart cart);
}
