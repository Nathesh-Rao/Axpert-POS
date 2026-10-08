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
}
