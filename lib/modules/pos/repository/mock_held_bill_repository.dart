import '../../../core/constants/storage_keys.dart';
import '../../../core/mock/mock_delay.dart';
import '../../../core/services/storage/local_store.dart';
import '../models/held_bill.dart';
import 'held_bill_repository.dart';

class MockHeldBillRepository implements HeldBillRepository {
  MockHeldBillRepository(this._store);

  final LocalStore _store;

  @override
  Future<List<HeldBill>> load() async {
    await MockDelay.wait();
    final json = await _store.read(StorageKeys.held);
    if (json is! List<dynamic>) return <HeldBill>[];
    return <HeldBill>[
      for (final item in json) HeldBill.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> save(List<HeldBill> bills) async {
    await MockDelay.wait();
    await _store.write(StorageKeys.held, <Map<String, dynamic>>[
      for (final b in bills) b.toJson(),
    ]);
  }
}
