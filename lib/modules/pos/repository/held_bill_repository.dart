import '../models/held_bill.dart';

abstract interface class HeldBillRepository {
  Future<List<HeldBill>> load();

  Future<void> save(List<HeldBill> bills);
}
