import 'package:get/get.dart';

import '../../../core/services/pricing/currency_registry.dart';
import '../../../features/session/presentation/controllers/active_session.dart';

import '../../../shared/controllers/clock_controller.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/controllers/search_field_controller.dart';
import '../../sales/controllers/sales_controller.dart';
import '../services/shift_summary.dart';
import '../../../core/session/session_scoped.dart';

/// Permanent shift state: today's summary from the sales ledger and the
/// clock's local day (Reports, Profile and the shift-close dialog read it) and
/// the signed-out flag of the "Counter closed" screen. Nothing is really
/// closed (no shift record, KG-159): the flag only shows the card, and it is
/// not persisted, so a restart starts a new shift as a page reload does.
class ShiftController extends GetxController implements SessionScoped {
  ShiftController({
    required this.sales,
    required this.clock,
    required this.overlay,
    required this.search,
    this.session,
  });

  final SalesController sales;
  final ClockController clock;
  final OverlayController overlay;
  final SearchFieldController search;
  final ActiveSession? session;

  final RxBool signedOut = false.obs;

  /// The summary for the current local day, computed on demand.
  ShiftSummary get today => ShiftSummary.of(
    sales.sales,
    clock.current,
    currency: session?.currency ?? CurrencyRegistry.inr,
  );

  /// "Confirm & close counter": `setSignedOut(true); setModal("")`.
  void closeCounter() {
    signedOut.value = true;
    overlay.close();
  }

  /// "Start new shift": `setSignedOut(false); focus()`.
  void startNewShift() {
    signedOut.value = false;
    search.refocus();
  }

  @override
  void resetForSignOut() {
    signedOut.value = false;
  }
}
