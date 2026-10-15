/// One packaging level offered to [StockFormatter].
class StockLevel {
  const StockLevel({required this.name, required this.quantityBaseMilli});

  final String name;

  /// Base units per package, in milli-units.
  final int quantityBaseMilli;
}

/// One part of a stock breakdown.
class StockPart {
  const StockPart({
    required this.name,
    required this.quantityMilli,
    required this.isBase,
  });

  /// Packaging name, or the base unit's name for the remainder.
  final String name;

  /// Whole packages are multiples of 1000; the base remainder may be
  /// fractional (10.5 kg is 10500).
  final int quantityMilli;
  final bool isBase;

  @override
  bool operator ==(Object other) =>
      other is StockPart &&
      other.name == name &&
      other.quantityMilli == quantityMilli &&
      other.isBase == isBase;

  @override
  int get hashCode => Object.hash(name, quantityMilli, isBase);

  @override
  String toString() => '$name:${quantityMilli}m${isBase ? ' (base)' : ''}';
}

/// A base quantity split into packages, largest first.
class StockBreakdown {
  const StockBreakdown({required this.parts, required this.negative});

  /// Never empty; zero stock is one base part of 0.
  final List<StockPart> parts;

  /// The stock is below zero; [parts] describe its absolute value.
  final bool negative;
}

/// Breaks a base quantity into the largest packagings, plain Dart.
///
/// 77 pieces with a carton of 24 and a pack of 6 are `3 carton + 0 pack + 5
/// pcs`, shown as `3 carton + 5 pcs` (empty levels are skipped). Greedy from the largest package; only whole packages, the base unit takes
/// the rest (so weights keep their fraction). Text is the caller's job.
class StockFormatter {
  const StockFormatter();

  StockBreakdown breakdown(
    int baseMilli,
    List<StockLevel> levels, {
    required String baseUnitName,
  }) {
    final negative = baseMilli < 0;
    var left = negative ? -baseMilli : baseMilli;
    final sorted = [
      for (final l in levels)
        if (l.quantityBaseMilli > 0) l,
    ]..sort((a, b) => b.quantityBaseMilli.compareTo(a.quantityBaseMilli));
    final parts = <StockPart>[];
    for (final level in sorted) {
      final count = left ~/ level.quantityBaseMilli;
      if (count == 0) continue;
      parts.add(
        StockPart(name: level.name, quantityMilli: count * 1000, isBase: false),
      );
      left -= count * level.quantityBaseMilli;
    }
    if (left > 0 || parts.isEmpty) {
      parts.add(
        StockPart(name: baseUnitName, quantityMilli: left, isBase: true),
      );
    }
    return StockBreakdown(parts: parts, negative: negative);
  }
}
