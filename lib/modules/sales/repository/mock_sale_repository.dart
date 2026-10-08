import '../../../core/constants/storage_keys.dart';
import '../../../core/mock/mock_delay.dart';
import '../../../core/services/storage/local_store.dart';
import '../models/sale.dart';
import 'sale_repository.dart';

class MockSaleRepository implements SaleRepository {
  MockSaleRepository(this._store);

  final LocalStore _store;

  @override
  Future<List<Sale>> load() async {
    await MockDelay.wait();
    final json = await _store.read(StorageKeys.sales);
    if (json is! List<dynamic>) return <Sale>[];
    return <Sale>[
      for (final item in json) Sale.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<void> save(List<Sale> sales) async {
    await MockDelay.wait();
    await _store.write(StorageKeys.sales, <Map<String, dynamic>>[
      for (final s in sales) s.toJson(),
    ]);
  }
}
