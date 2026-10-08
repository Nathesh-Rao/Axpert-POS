import 'package:get/get.dart';

import '../../../shared/controllers/search_field_controller.dart';
import '../../customers/controllers/customers_controller.dart';
import '../../customers/models/customer.dart';
import '../models/cart.dart';
import 'cart_controller.dart';

/// Cart metadata edits (prototype `dispatch({type: "metadata"})`): sale type,
/// customer, note. Changing the customer resets the redeemed points.
class CartMetaController extends GetxController {
  CartMetaController({
    required this.cart,
    required this.customers,
    required this.search,
  });

  final CartController cart;
  final CustomersController customers;
  final SearchFieldController search;

  Customer get customer =>
      customers.byIdOrFirst(cart.cart.value.customer) ?? _walkIn;

  static const Customer _walkIn = Customer(
    id: Customer.walkInId,
    name: '',
    phone: '',
    email: '',
    member: '',
    points: 0,
  );

  void setSaleType(SaleType type) =>
      cart.patch((c) => c.copyWith(saleType: type));

  /// Dropdown change: select the customer, reset points, refocus search.
  void selectCustomer(String id) {
    setCustomer(id);
    search.refocus();
  }

  void setCustomer(String id) =>
      cart.patch((c) => c.copyWith(customer: id, points: 0));

  void setNote(String note) => cart.patch((c) => c.copyWith(note: note));
}
