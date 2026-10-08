import 'package:get/get.dart';

import '../../../shared/controllers/filtered_list_controller.dart';
import '../models/sale.dart';
import 'sales_controller.dart';

/// The Sales page: the ledger filtered by `number customer`, newest first.
class SalesPageController extends FilteredListController<Sale> {
  SalesPageController({required this.ledger, required super.pageFilter});

  final SalesController ledger;

  @override
  RxList<Sale> get source => ledger.sales;

  @override
  bool get newestFirst => true;

  @override
  String keyOf(Sale item) => '${item.number} ${item.customer}'.toLowerCase();
}
