import 'package:get/get.dart';

import '../../../shared/controllers/clock_controller.dart';
import '../../shift/controllers/shift_controller.dart';
import '../../shift/services/shift_summary.dart';

/// The Reports page: today's summary, refreshed when a sale is added and when
/// the local day changes (the clock ticks while the page is open).
class ReportsController extends GetxController {
  ReportsController({required this.shift});

  final ShiftController shift;

  /// Today's summary; computed in [onInit] (plain reads) so the first build
  /// never creates or changes it.
  late final Rx<ShiftSummary> summary;
  final List<Worker> _workers = <Worker>[];

  ClockController get _clock => shift.clock;

  @override
  void onInit() {
    super.onInit();
    summary = shift.today.obs;
    _clock.attach();
    _workers
      ..add(ever(shift.sales.sales, (_) => refresh()))
      ..add(
        ever<DateTime>(_clock.now, (now) {
          if (!ShiftSummary.sameDay(now, summary.value.day)) refresh();
        }),
      );
  }

  @override
  void refresh() => summary.value = shift.today;

  @override
  void onClose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    _clock.detach();
    super.onClose();
  }
}
