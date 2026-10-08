import 'package:get/get.dart';

import '../../../shared/controllers/overlay_controller.dart';
import '../models/sale.dart';
import 'sales_controller.dart';

/// The Reprint dialog ("Recent sales"): the sales newest first; a row opens
/// its receipt.
class ReprintController extends GetxController {
  ReprintController({required this.sales, required this.overlay});

  final SalesController sales;
  final OverlayController overlay;

  /// `sales.slice().reverse()`.
  List<Sale> get recent => sales.sales.reversed.toList();

  void open(Sale sale) => overlay.open('receipt', payload: sale);
}
