import 'package:get/get.dart';

import '../../../core/services/pricing/pricing_helpers.dart';

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

  /// `total / rate` shown with 2 decimals (`toFixed(2)`): the plain-Dart
  /// [PricingHelpers.forexConvertHundredths] formatted here. Zero when the rate
  /// is not positive.
  String converted(Money total) {
    final cents = PricingHelpers.forexConvertHundredths(
      total: total,
      rateMilli: rateMilli,
    );
    final frac = (cents % 100).toString().padLeft(2, '0');
    return '${cents ~/ 100}.$frac';
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
