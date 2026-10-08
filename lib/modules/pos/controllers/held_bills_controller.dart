import 'package:get/get.dart';

import '../models/held_bill.dart';
import '../repository/held_bill_repository.dart';

/// Permanent list of held bills (prototype `held`).
class HeldBillsController extends GetxController {
  HeldBillsController(this._repository);

  final HeldBillRepository _repository;

  final RxList<HeldBill> bills = <HeldBill>[].obs;

  int get count => bills.length;

  Future<void> load() async {
    bills.assignAll(await _repository.load());
  }

  /// Clear Hold, after its confirmation (`setHeld([])`).
  Future<void> clearAll() {
    bills.clear();
    return save();
  }

  Future<void> save() => _repository.save(bills.toList());
}
