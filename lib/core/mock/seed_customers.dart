import '../../modules/customers/models/customer.dart';

/// The prototype's 4 customers (`data.ts` `sampleCustomers`).
abstract final class SeedCustomers {
  static const List<Customer> customers = <Customer>[
    Customer(
      id: Customer.walkInId,
      name: 'Walk-in Customer',
      phone: '',
      email: '',
      member: '',
      points: 0,
    ),
    Customer(
      id: '1',
      name: 'Ananya Sharma',
      phone: '9876543210',
      email: 'ananya@example.com',
      member: 'MG1001',
      points: 250,
    ),
    Customer(
      id: '2',
      name: 'Rahul Mehta',
      phone: '9876543211',
      email: 'rahul@example.com',
      member: 'MG1002',
      points: 120,
    ),
    Customer(
      id: '3',
      name: 'Priya Nair',
      phone: '9876543212',
      email: 'priya@example.com',
      member: 'MG1003',
      points: 400,
    ),
  ];
}
