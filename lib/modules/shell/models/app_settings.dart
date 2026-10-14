import '../../../core/constants/storage_keys.dart';

/// Persistent shell settings (the prototype's store, dark, beep and counter
/// keys). The forex rate is store data now (`store_forex`).
class AppSettings {
  const AppSettings({
    required this.store,
    required this.dark,
    required this.beep,
    required this.counter,
    this.printPaperMm = defaultPrintPaperMm,
    this.posProductsStep = defaultPosProductsStep,
    this.posBillingOpen = true,
  });

  /// Receipt paper width used until a setting says otherwise.
  static const int defaultPrintPaperMm = 80;

  /// Products panel closed (0), narrow (25) or wide (75) on a new device.
  static const int defaultPosProductsStep = 0;

  /// Defaults: light, beep on. `store` and `counter` are
  /// legacy keys: the store and counter come from the database session now
  /// (DEC-132) and nothing reads these two values.
  static const AppSettings defaults = AppSettings(
    store: '',
    dark: false,
    beep: true,
    counter: '',
  );

  /// Reads the per-key JSON map written by the repository.
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    store: json[StorageKeys.store] as String? ?? defaults.store,
    dark: json[StorageKeys.dark] as bool? ?? defaults.dark,
    beep: json[StorageKeys.beep] as bool? ?? defaults.beep,
    counter: json[StorageKeys.counter] as String? ?? defaults.counter,
    printPaperMm:
        json[StorageKeys.printPaperMm] as int? ?? defaults.printPaperMm,
    posProductsStep:
        json[StorageKeys.posProductsStep] as int? ?? defaults.posProductsStep,
    posBillingOpen:
        json[StorageKeys.posBillingOpen] as bool? ?? defaults.posBillingOpen,
  );

  final String store;
  final bool dark;
  final bool beep;
  final String counter;

  /// Receipt paper width in millimetres (80 or 58 for thermal rolls).
  final int printPaperMm;

  /// The user's chosen POS layout on this device: Products panel step (0, 25,
  /// 75) and Billing open or collapsed. A view preference, not business data.
  final int posProductsStep;
  final bool posBillingOpen;

  Map<String, dynamic> toJson() => <String, dynamic>{
    StorageKeys.store: store,
    StorageKeys.dark: dark,
    StorageKeys.beep: beep,
    StorageKeys.counter: counter,
    StorageKeys.printPaperMm: printPaperMm,
    StorageKeys.posProductsStep: posProductsStep,
    StorageKeys.posBillingOpen: posBillingOpen,
  };

  AppSettings copyWith({
    String? store,
    bool? dark,
    bool? beep,
    String? counter,
    int? printPaperMm,
    int? posProductsStep,
    bool? posBillingOpen,
  }) => AppSettings(
    store: store ?? this.store,
    dark: dark ?? this.dark,
    beep: beep ?? this.beep,
    counter: counter ?? this.counter,
    printPaperMm: printPaperMm ?? this.printPaperMm,
    posProductsStep: posProductsStep ?? this.posProductsStep,
    posBillingOpen: posBillingOpen ?? this.posBillingOpen,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.store == store &&
      other.dark == dark &&
      other.beep == beep &&
      other.counter == counter &&
      other.printPaperMm == printPaperMm &&
      other.posProductsStep == posProductsStep &&
      other.posBillingOpen == posBillingOpen;

  @override
  int get hashCode => Object.hash(
    store,
    dark,
    beep,
    counter,
    printPaperMm,
    posProductsStep,
    posBillingOpen,
  );
}
