import 'money.dart';

/// One component of the total tax (a label and its amount).
class TaxPart {
  const TaxPart(this.label, this.amount);

  final String label;
  final Money amount;

  @override
  bool operator ==(Object other) =>
      other is TaxPart && other.label == label && other.amount == amount;

  @override
  int get hashCode => Object.hash(label, amount);
}

/// Splits the already rounded total tax into equal components (CGST + SGST).
/// Largest remainder: the minor units left over go to the LAST components, so
/// the parts always add up to the tax exactly. The odd-unit convention (SGST
/// gets it) is not confirmed with an accountant (KG-190).
abstract final class TaxSplit {
  static List<TaxPart> parts(Money tax, List<String> labels) {
    if (labels.isEmpty) return const <TaxPart>[];
    final n = labels.length;
    final base = tax.minor ~/ n;
    final extra = tax.minor - base * n;
    return <TaxPart>[
      for (var i = 0; i < n; i++)
        TaxPart(
          labels[i],
          Money(base + (i >= n - extra ? 1 : 0), tax.currency),
        ),
    ];
  }
}
