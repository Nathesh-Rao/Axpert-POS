/// Same keys as the prototype's localStorage (`axpert-` prefix, DEC-042).
abstract final class StorageKeys {
  static const String _prefix = 'axpert-';

  static const String cart = '${_prefix}cart';
  static const String products = '${_prefix}products';
  static const String customers = '${_prefix}customers';
  static const String held = '${_prefix}held';
  static const String sales = '${_prefix}sales';
  static const String store = '${_prefix}store';
  static const String dark = '${_prefix}dark';
  static const String beep = '${_prefix}beep';
  static const String counter = '${_prefix}counter';
  static const String rate = '${_prefix}rate';

  /// Set while Drift may be behind LocalStore for settings (DEC-125).
  static const String settingsDriftStale = '${_prefix}settings-drift-stale';

  /// Set while Drift may be behind LocalStore for customers (DEC-126).
  static const String customersDriftStale = '${_prefix}customers-drift-stale';
  static const String heldDriftStale = '${_prefix}held-drift-stale';

  /// Set while Drift may be behind LocalStore for products (DEC-128).
  static const String productsDriftStale = '${_prefix}products-drift-stale';

  /// Set while Drift may be behind LocalStore for sales (DEC-129).
  static const String salesDriftStale = '${_prefix}sales-drift-stale';
}
