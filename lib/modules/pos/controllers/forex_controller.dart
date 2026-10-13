import 'package:get/get.dart';

import '../../../core/services/pricing/currency_registry.dart';
import '../../../core/services/pricing/money.dart';
import '../../../core/services/pricing/pricing_helpers.dart';
import '../../../core/utils/decimal_text.dart';
import '../../../features/session/domain/entities/session_entities.dart';
import '../../../features/session/presentation/controllers/active_session.dart';

/// The forex card: the active store's foreign currencies and their rates come
/// from the database (`store_forex`, via [ActiveSession.forex]); the selector
/// only picks which row converts the total.
class ForexController extends GetxController {
  ForexController(this._session);

  final ActiveSession _session;

  /// Selected foreign currency code (empty when the store has none).
  final RxString currency = ''.obs;

  /// Foreign currency codes of the store, in row order.
  List<String> get codes => <String>[for (final r in _session.forex) r.code];

  /// False hides the whole forex panel.
  bool get available => _session.forex.isNotEmpty;

  ForexRate? get selected =>
      _session.forex.firstWhereOrNull((r) => r.code == currency.value);

  /// Rate of the selected row, scaled by 1,000,000 (0 without one).
  int get rateMicro => selected?.rateMicro ?? 0;

  /// The rate as text (`83.2`), no floating point.
  String get rateText => DecimalText.scaled(rateMicro, 6);

  /// [total] in the selected foreign currency (its own decimals), converted
  /// once with exact integer maths; `0` without a selected row.
  String converted(Money total) {
    final row = selected;
    if (row == null) return '0';
    final foreign = CurrencyRegistry.byCode(row.code);
    final minor = PricingHelpers.forexConvert(
      total: total,
      foreign: foreign,
      rateMicro: row.rateMicro,
    );
    return DecimalText.fixed(minor, foreign.exponent);
  }

  @override
  void onInit() {
    super.onInit();
    _follow();
    ever(_session.forex, (_) => _follow());
  }

  void _follow() {
    if (_session.forex.any((r) => r.code == currency.value)) return;
    currency.value = _session.forex.isEmpty ? '' : _session.forex.first.code;
  }

  void setCurrency(String value) => currency.value = value;
}
