import '../models/sale.dart';

abstract interface class SaleRepository {
  Future<List<Sale>> load();

  Future<void> save(List<Sale> sales);
}
