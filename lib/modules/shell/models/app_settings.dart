import '../../../core/constants/storage_keys.dart';

/// Persistent shell settings (the prototype's store, dark, beep, counter and
/// rate keys). The forex rate is integer milli-units: 8.561 is 8561.
class AppSettings {
  const AppSettings({
    required this.store,
    required this.dark,
    required this.beep,
    required this.counter,
    required this.rateMilli,
  });

  /// Defaults: light, beep on, forex rate 8.561. `store` and `counter` are
  /// legacy keys: the store and counter come from the database session now
  /// (DEC-132) and nothing reads these two values.
  static const AppSettings defaults = AppSettings(
    store: '',
    dark: false,
    beep: true,
    counter: '',
    rateMilli: 8561,
  );

  /// Reads the per-key JSON map written by the repository.
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    store: json[StorageKeys.store] as String? ?? defaults.store,
    dark: json[StorageKeys.dark] as bool? ?? defaults.dark,
    beep: json[StorageKeys.beep] as bool? ?? defaults.beep,
    counter: json[StorageKeys.counter] as String? ?? defaults.counter,
    rateMilli: json[StorageKeys.rate] as int? ?? defaults.rateMilli,
  );

  final String store;
  final bool dark;
  final bool beep;
  final String counter;
  final int rateMilli;

  Map<String, dynamic> toJson() => <String, dynamic>{
    StorageKeys.store: store,
    StorageKeys.dark: dark,
    StorageKeys.beep: beep,
    StorageKeys.counter: counter,
    StorageKeys.rate: rateMilli,
  };

  AppSettings copyWith({
    String? store,
    bool? dark,
    bool? beep,
    String? counter,
    int? rateMilli,
  }) => AppSettings(
    store: store ?? this.store,
    dark: dark ?? this.dark,
    beep: beep ?? this.beep,
    counter: counter ?? this.counter,
    rateMilli: rateMilli ?? this.rateMilli,
  );

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.store == store &&
      other.dark == dark &&
      other.beep == beep &&
      other.counter == counter &&
      other.rateMilli == rateMilli;

  @override
  int get hashCode => Object.hash(store, dark, beep, counter, rateMilli);
}
