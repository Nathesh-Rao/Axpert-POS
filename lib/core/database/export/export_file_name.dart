/// `pos_<store code>_<yyyyMMdd_HHmm>.db`. The schema has no store code, so
/// the code is a slug of the store name (`A-Za-z0-9_-`), or the first 8
/// characters of the store id when the name has no usable character (DEC-145).
String databaseExportFileName({
  required String storeName,
  required String storeId,
  required DateTime now,
}) {
  final slug = storeName
      .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final cleanId = storeId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
  final code = slug.isNotEmpty
      ? slug
      : (cleanId.length > 8 ? cleanId.substring(0, 8) : cleanId);
  String two(int v) => v.toString().padLeft(2, '0');
  final stamp =
      '${now.year.toString().padLeft(4, '0')}${two(now.month)}${two(now.day)}'
      '_${two(now.hour)}${two(now.minute)}';
  return 'pos_${code.isEmpty ? 'store' : code}_$stamp.db';
}
