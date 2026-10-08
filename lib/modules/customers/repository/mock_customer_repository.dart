import '../../../core/constants/storage_keys.dart';
import '../../../core/mock/mock_delay.dart';
import '../../../core/mock/seed_customers.dart';
import '../../../core/services/storage/local_store.dart';
import '../../../core/services/storage/local_store_seeder.dart';
import '../models/customer.dart';
import 'customer_repository.dart';

class MockCustomerRepository implements CustomerRepository {
  MockCustomerRepository(this._store);

  final LocalStore _store;

  @override
  Future<List<Customer>> load() async {
    await MockDelay.wait();
    final json = await LocalStoreSeeder.seedIfMissing(
      _store,
      StorageKeys.customers,
      _encode(SeedCustomers.customers),
    );
    return <Customer>[
      for (final item in json as List<dynamic>)
        Customer.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> save(List<Customer> customers) async {
    await MockDelay.wait();
    await _store.write(StorageKeys.customers, _encode(customers));
  }

  static List<Map<String, dynamic>> _encode(List<Customer> customers) =>
      <Map<String, dynamic>>[for (final c in customers) c.toJson()];
}
