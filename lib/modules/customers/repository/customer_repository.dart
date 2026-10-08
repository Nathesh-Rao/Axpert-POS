import '../models/customer.dart';

abstract interface class CustomerRepository {
  Future<List<Customer>> load();

  Future<void> save(List<Customer> customers);
}
