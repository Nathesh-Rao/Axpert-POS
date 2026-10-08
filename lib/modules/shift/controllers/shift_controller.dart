import 'package:get/get.dart';

import '../../../shared/controllers/clock_controller.dart';
import '../../sales/controllers/sales_controller.dart';
import '../services/shift_summary.dart';

/// Permanent shift state: today's summary from the sales ledger and the
/// clock's local day (Reports, Profile and the shift-close dialog read it).
class ShiftController extends GetxController {
  ShiftController({required this.sales, required this.clock});

  final SalesController sales;
  final ClockController clock;

  /// The summary for the current local day, computed on demand.
  ShiftSummary get today => ShiftSummary.of(sales.sales, clock.current);
}
