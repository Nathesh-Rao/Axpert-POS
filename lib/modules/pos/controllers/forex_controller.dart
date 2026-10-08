import 'package:get/get.dart';

import '../../../core/utils/decimal_input.dart';
import '../../../core/services/pricing/money.dart';
import '../../shell/controllers/settings_controller.dart';

/// The forex card (prototype `converted`, `currency`, `rate`). The selector
/// only changes the label (KG-107); the rate is milli-units, persisted
/// through the settings.
class ForexController extends GetxController {
  ForexController(this._settings);

  /// Selector values in prototype order.
  static const List<String> currencies = <String>['USD', 'EUR', 'AED', 'FC'];

  final SettingsController _settings;

  final RxString currency = 'USD'.obs;

  /// Observable stored rate (the rate field follows it).
  RxInt get settingsRate => _rateRx;
  late final RxInt _rateRx = _settings.settings.value.rateMilli.obs;

  int get rateMilli => _settings.settings.value.rateMilli;

  /// `total / rate` shown with 2 decimals (`toFixed(2)`, half-up), integer
  /// arithmetic only. Zero when the rate is not positive.
  String converted(Money total) {
    final rate = rateMilli;
    if (rate <= 0) return '0.00';
    // total.minor / 10^exp / (rate / 1000), scaled to hundredths.
    var unit = 1;
    for (var i = 0; i < total.currency.exponent; i++) {
      unit *= 10;
    }
    final numerator = total.minor * 1000 * 100;
    final denominator = unit * rate;
    final cents = (numerator * 2 + denominator) ~/ (denominator * 2);
    final whole = cents ~/ 100;
    final frac = (cents % 100).toString().padLeft(2, '0');
    return '$whole.$frac';
  }

  /// Rate field commit (`next > 0` only, 3 decimals, KG-003).
  void commitRate(String text) {
    final next = DecimalInput.tryScaled(text, 3);
    if (next != null && next > 0) _settings.setRateMilli(next);
  }

  @override
  void onInit() {
    super.onInit();
    ever(_settings.settings, (s) => _rateRx.value = s.rateMilli);
  }

  void setCurrency(String value) => currency.value = value;
}
