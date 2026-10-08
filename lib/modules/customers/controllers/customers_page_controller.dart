import 'package:get/get.dart';

import '../../../shared/controllers/filtered_list_controller.dart';
import '../models/customer.dart';
import 'customers_controller.dart';

/// The Customers page: the customer list filtered by `name phone`.
class CustomersPageController extends FilteredListController<Customer> {
  CustomersPageController({required this.customers, required super.pageFilter});

  final CustomersController customers;

  @override
  RxList<Customer> get source => customers.customers;

  @override
  String keyOf(Customer item) => '${item.name} ${item.phone}'.toLowerCase();
}
