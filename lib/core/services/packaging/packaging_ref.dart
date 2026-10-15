/// Snapshot of the packaging a cart or sale line was sold in (DEC-151). It is
/// copied onto the line, so history stays correct when the packaging is
/// edited later. `qty` of such a line counts packages, its `price` is the
/// package price.
class PackagingRef {
  const PackagingRef({
    required this.id,
    required this.unitName,
    required this.quantityBaseMilli,
  });

  factory PackagingRef.fromJson(Map<String, dynamic> json) => PackagingRef(
    id: json['id'] as String,
    unitName: json['unitName'] as String,
    quantityBaseMilli: json['quantityBaseMilli'] as int,
  );

  final String id;

  /// Name of the packaging when it was sold ("Carton").
  final String unitName;

  /// Base units per package, in milli-units (24000 = 24).
  final int quantityBaseMilli;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'unitName': unitName,
    'quantityBaseMilli': quantityBaseMilli,
  };

  @override
  bool operator ==(Object other) =>
      other is PackagingRef &&
      other.id == id &&
      other.unitName == unitName &&
      other.quantityBaseMilli == quantityBaseMilli;

  @override
  int get hashCode => Object.hash(id, unitName, quantityBaseMilli);
}
