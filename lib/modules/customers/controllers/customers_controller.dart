import 'package:get/get.dart';

import '../models/customer.dart';
import '../repository/customer_repository.dart';

/// Permanent customer list.
class CustomersController extends GetxController {
  CustomersController(this._repository);

  final CustomerRepository _repository;

  final RxList<Customer> customers = <Customer>[].obs;

  Future<void> load() async {
    customers.assignAll(await _repository.load());
  }

  /// The customer with [id], else the first one (the prototype's fallback).
  Customer? byIdOrFirst(String id) {
    if (customers.isEmpty) return null;
    return customers.firstWhereOrNull((c) => c.id == id) ?? customers.first;
  }

  /// Subtracts redeemed points (`points - totals.points`) and persists.
  Future<void> deductPoints(String id, int points) {
    final index = customers.indexWhere((c) => c.id == id);
    if (index < 0 || points == 0) return Future<void>.value();
    final c = customers[index];
    customers[index] = Customer(
      id: c.id,
      name: c.name,
      phone: c.phone,
      email: c.email,
      member: c.member,
      points: c.points - points,
    );
    return save();
  }

  Future<void> save() => _repository.save(customers.toList());
}
