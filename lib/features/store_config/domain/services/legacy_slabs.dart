import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/pricing/tax_components.dart';
import '../../../../core/utils/decimal_text.dart';
import '../../../session/domain/entities/session_entities.dart';

/// Turns the slabs of a legacy regime (bare rates plus split parts) into
/// editable component slabs, the way the bill already splits them: equal
/// parts, the odd basis point goes to the last part. The default slab is not
/// guessed: it is the first slab with a rate above zero.
abstract final class LegacySlabs {
  static List<TaxSlabInfo> from(TaxRegimeInfo? regime) {
    if (regime == null) return const <TaxSlabInfo>[];
    final slabs = <TaxSlabInfo>[];
    var defaultSet = false;
    for (final s in regime.slabs) {
      final isDefault = !defaultSet && s.rateBp > 0;
      if (isDefault) defaultSet = true;
      slabs.add(
        TaxSlabInfo.of(
          id: '',
          name: _named(s.label)
              ? s.label
              : AppStrings.current.taxRateLabel(
                  regime.label,
                  DecimalText.scaled(s.rateBp, 2),
                ),
          isDefault: isDefault,
          components: _components(regime, s.rateBp),
        ),
      );
    }
    if (!defaultSet && slabs.isNotEmpty) {
      final first = slabs.first;
      slabs[0] = TaxSlabInfo.of(
        id: first.id,
        name: first.label,
        isDefault: true,
        components: first.components,
      );
    }
    return slabs;
  }

  /// A slab label that is a real name (not empty, not just a percentage).
  static bool _named(String label) =>
      label.isNotEmpty && !RegExp(r'^[\d.]+\s*%$').hasMatch(label);

  static List<TaxComponent> _components(TaxRegimeInfo regime, int rateBp) {
    final parts = regime.splitParts;
    if (parts.length < 2) {
      return <TaxComponent>[
        TaxComponent(
          label: parts.isEmpty ? regime.label : parts.single,
          rateBp: rateBp,
        ),
      ];
    }
    final each = rateBp ~/ parts.length;
    final extra = rateBp - each * parts.length;
    return <TaxComponent>[
      for (var i = 0; i < parts.length; i++)
        TaxComponent(
          label: parts[i],
          rateBp: each + (i >= parts.length - extra ? 1 : 0),
        ),
    ];
  }
}
