import 'package:get/get.dart';

import '../models/sale.dart';
import '../repository/sale_repository.dart';

/// Permanent sales ledger (prototype `sales`). Sales are appended on checkout;
/// numbering comes from the list length (KG-008).
class SalesController extends GetxController {
  SalesController(this._repository);

  final SaleRepository _repository;

  final RxList<Sale> sales = <Sale>[].obs;

  Future<void> load() async {
    sales.assignAll(await _repository.load());
  }

  Future<void> add(Sale sale) {
    sales.add(sale);
    return _repository.save(sales.toList());
  }

  /// Swaps the sale with the same number in memory (a refund changes only
  /// `returned`); the caller persists through its own repository.
  void replace(Sale updated) {
    final index = sales.indexWhere((s) => s.number == updated.number);
    if (index >= 0) sales[index] = updated;
  }
}
