/// Identity of a cart or sale line: the product and the packaging it is sold
/// in (DEC-154). A null [packagingId] is the base unit. The same product in
/// two packagings is two lines; a carton never merges into pieces.
class LineKey {
  const LineKey(this.productId, [this.packagingId]);

  /// The base-unit line of [productId].
  const LineKey.base(this.productId) : packagingId = null;

  /// Parses [text] (`"12"` or `"12|<packaging id>"`), the string form used in
  /// JSON maps and the stored refund order. Plain product ids stay what the
  /// prototype wrote, so old data loads unchanged.
  factory LineKey.parse(String text) {
    final cut = text.indexOf('|');
    if (cut < 0) return LineKey(int.parse(text));
    return LineKey(int.parse(text.substring(0, cut)), text.substring(cut + 1));
  }

  final int productId;
  final String? packagingId;

  bool get isBase => packagingId == null;

  /// `"12"` for the base unit, `"12|<packaging id>"` otherwise.
  String get text =>
      packagingId == null ? '$productId' : '$productId|$packagingId';

  @override
  bool operator ==(Object other) =>
      other is LineKey &&
      other.productId == productId &&
      other.packagingId == packagingId;

  @override
  int get hashCode => Object.hash(productId, packagingId);

  @override
  String toString() => 'LineKey($text)';
}
