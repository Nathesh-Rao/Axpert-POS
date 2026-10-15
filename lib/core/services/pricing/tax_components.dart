import 'money.dart';
import 'rational.dart';
import 'tax_split.dart';

/// One tax component of a slab: a label and a rate in basis points (`CGST`
/// 900, `Service charge` 500). A disabled component is kept but not applied.
class TaxComponent {
  const TaxComponent({
    required this.label,
    required this.rateBp,
    this.enabled = true,
  });

  final String label;
  final int rateBp;
  final bool enabled;

  TaxComponent copyWith({String? label, int? rateBp, bool? enabled}) =>
      TaxComponent(
        label: label ?? this.label,
        rateBp: rateBp ?? this.rateBp,
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      other is TaxComponent &&
      other.label == label &&
      other.rateBp == rateBp &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(label, rateBp, enabled);
}

/// The exact tax of one cart line and the rate that selected its slab.
class TaxLineShare {
  const TaxLineShare({required this.tax, required this.rateBp});

  final Rational tax;
  final int rateBp;
}

/// Splits the already rounded total tax across tax components. The ONE
/// rounding point of the split: the exact tax of every line is weighted by its
/// slab's components, and the rounded total is shared out by largest
/// remainder (ties go to the LAST component, like [TaxSplit]), so the parts
/// always add up to the tax. Components with the same label merge.
abstract final class TaxComponentAllocator {
  static List<TaxPart> allocate({
    required Money tax,
    required List<TaxLineShare> lines,
    required List<TaxComponent> Function(int rateBp) componentsFor,
    required List<TaxComponent> fallback,
  }) {
    final order = <String>[];
    final weight = <String, Rational>{};
    void register(String label) {
      if (!weight.containsKey(label)) {
        order.add(label);
        weight[label] = Rational.zero;
      }
    }

    for (final line in lines) {
      final comps = [
        for (final c in componentsFor(line.rateBp))
          if (c.enabled) c,
      ];
      var total = 0;
      for (final c in comps) {
        total += c.rateBp;
      }
      for (final c in comps) {
        register(c.label);
        if (total > 0 && c.rateBp > 0) {
          weight[c.label] =
              weight[c.label]! +
              line.tax * Rational.fromInt(c.rateBp) / Rational.fromInt(total);
        }
      }
    }
    if (order.isEmpty) {
      for (final c in fallback) {
        if (c.enabled) register(c.label);
      }
    }
    if (order.isEmpty) return const <TaxPart>[];
    var sum = Rational.zero;
    for (final w in weight.values) {
      sum += w;
    }
    if (sum.isZero) {
      return TaxSplit.parts(tax, order);
    }
    final taxR = Rational.fromInt(tax.minor);
    final floors = <int>[];
    final fractions = <Rational>[];
    var given = 0;
    for (final label in order) {
      final exact = taxR * weight[label]! / sum;
      final floor = exact.floor().toInt();
      floors.add(floor);
      fractions.add(exact - Rational.fromInt(floor));
      given += floor;
    }
    var left = tax.minor - given;
    final ranked = List<int>.generate(order.length, (i) => i)
      ..sort((a, b) {
        final byFraction = fractions[b].compareTo(fractions[a]);
        return byFraction != 0 ? byFraction : b.compareTo(a);
      });
    for (final i in ranked) {
      if (left <= 0) break;
      floors[i] += 1;
      left -= 1;
    }
    return <TaxPart>[
      for (var i = 0; i < order.length; i++)
        TaxPart(order[i], Money(floors[i], tax.currency)),
    ];
  }
}
