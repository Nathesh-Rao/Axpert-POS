import '../../../../core/services/pricing/currency.dart';
import '../../../../core/services/pricing/money.dart';
import '../../../../core/services/pricing/tax_components.dart';
import '../../../../core/services/pricing/tax_split.dart';

/// A store row (receipt details and currency come from here).
class StoreInfo {
  const StoreInfo({
    required this.id,
    required this.name,
    required this.currencyCode,
    this.address = '',
    this.phone = '',
    this.taxId = '',
    this.receiptHeader = '',
    this.receiptFooter = '',
    this.region = '',
    this.allowNegativeStock = false,
    this.stateCode = '',
  });

  final String id;
  final String name;
  final String currencyCode;
  final String address;
  final String phone;
  final String taxId;
  final String receiptHeader;
  final String receiptFooter;
  final String region;

  /// A sale may take stock below zero (with a warning), DEC-148.
  final bool allowNegativeStock;

  /// State or region inside the country (empty = not set).
  final String stateCode;
}

class CounterInfo {
  const CounterInfo({
    required this.id,
    required this.storeId,
    required this.name,
  });

  final String id;
  final String storeId;
  final String name;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String username;
  final String displayName;

  /// `admin`, `manager` or `cashier`; shown, not enforced yet.
  final String role;
}

/// A user's row with the stored hash (never shown or logged).
class UserCredential {
  const UserCredential({
    required this.user,
    required this.salt,
    required this.passwordHash,
    required this.hashAlgo,
  });

  final AppUser user;
  final String salt;
  final String passwordHash;
  final String hashAlgo;
}

/// One store a user may open and the counters they may pick in it.
class StoreAccess {
  const StoreAccess({required this.store, required this.counters});

  final StoreInfo store;
  final List<CounterInfo> counters;
}

/// The currency rows plus the quick cash amounts of each (whole units).
class CurrencyRow {
  const CurrencyRow({required this.currency, required this.quickCash});

  final Currency currency;
  final List<int> quickCash;
}

/// One foreign currency of a store: 1 [code] unit = `rateMicro / 1e6` units of
/// the store's currency.
class ForexRate {
  const ForexRate({required this.code, required this.rateMicro});

  final String code;
  final int rateMicro;
}

/// The slab sets a slab belongs to: bills use [standard]; [interState] holds
/// the IGST style slabs (the per-sale switch is a later task).
abstract final class TaxScheme {
  static const String standard = 'standard';
  static const String interState = 'inter_state';
}

/// A slab of a tax regime. [components] is empty for a legacy slab (a bare
/// rate): the regime then splits it equally over its `splitParts`.
class TaxSlabInfo {
  const TaxSlabInfo({
    required this.rateBp,
    this.label = '',
    this.id = '',
    this.scheme = TaxScheme.standard,
    this.enabled = true,
    this.isDefault = false,
    this.components = const <TaxComponent>[],
  });

  /// A slab whose total is the sum of its enabled components.
  factory TaxSlabInfo.of({
    required String id,
    required String name,
    required List<TaxComponent> components,
    String scheme = TaxScheme.standard,
    bool enabled = true,
    bool isDefault = false,
  }) => TaxSlabInfo(
    id: id,
    label: name,
    rateBp: totalOf(components),
    scheme: scheme,
    enabled: enabled,
    isDefault: isDefault,
    components: components,
  );

  static int totalOf(List<TaxComponent> components) {
    var total = 0;
    for (final c in components) {
      if (c.enabled) total += c.rateBp;
    }
    return total;
  }

  final String id;

  /// Total rate: the sum of the enabled components.
  final int rateBp;

  /// The slab name (`GST 18%`), the caption of a cart line.
  final String label;
  final String scheme;
  final bool enabled;
  final bool isDefault;
  final List<TaxComponent> components;
}

/// The tax setup of a store: its slabs (store rows, or the legacy regime of
/// its region) and the label of the tax heading.
class TaxRegimeInfo {
  const TaxRegimeInfo({
    required this.region,
    required this.label,
    required this.inclusive,
    this.splitParts = const <String>[],
    this.slabs = const <TaxSlabInfo>[],
  });

  final String region;
  final String label;
  final bool inclusive;
  final List<String> splitParts;
  final List<TaxSlabInfo> slabs;

  bool get hasComponentSlabs => slabs.any((s) => s.components.isNotEmpty);

  /// Slab that prices a product of [rateBp]: standard scheme, enabled, equal
  /// total. Enabled slabs of one scheme have unique totals (validated); for
  /// legacy rows the tiebreak is default first, then position (list order).
  TaxSlabInfo? slabFor(int rateBp, {String scheme = TaxScheme.standard}) {
    final matches = [
      for (final s in slabs)
        if (s.enabled && s.scheme == scheme && s.rateBp == rateBp) s,
    ];
    if (matches.isEmpty) return null;
    for (final s in matches) {
      if (s.isDefault) return s;
    }
    return matches.first;
  }

  /// Slab used for an empty cart and as the default of the page preview.
  TaxSlabInfo? get defaultSlab {
    final standard = [
      for (final s in slabs)
        if (s.enabled && s.scheme == TaxScheme.standard) s,
    ];
    for (final s in standard) {
      if (s.isDefault) return s;
    }
    return standard.isEmpty ? null : standard.first;
  }

  List<TaxComponent> _legacy() {
    // Equal weights (rate 1 each): the legacy split is an equal split.
    if (splitParts.isEmpty) {
      return label.isEmpty
          ? const <TaxComponent>[]
          : <TaxComponent>[TaxComponent(label: label, rateBp: 1)];
    }
    return <TaxComponent>[
      for (final p in splitParts) TaxComponent(label: p, rateBp: 1),
    ];
  }

  /// Components that tax a product of [rateBp] (a slab without components,
  /// or a rate with no slab, falls back to the legacy split).
  List<TaxComponent> componentsFor(int rateBp) {
    final slab = slabFor(rateBp);
    if (slab != null && slab.components.isNotEmpty) return slab.components;
    return _legacy();
  }

  /// Tax name of the heading and the captions: the regime label for a legacy
  /// regime; for store slabs the label of the single component of the default
  /// slab, or "" when it has several (the heading then reads "Tax Amount").
  String get taxName {
    if (!hasComponentSlabs) return label;
    final comps = [
      for (final c in defaultSlab?.components ?? const <TaxComponent>[])
        if (c.enabled) c,
    ];
    return comps.length == 1 ? comps.single.label : '';
  }

  /// Tax lines of [tax]: one per component, summing exactly to [tax].
  List<TaxPart> partsOf(Money tax, List<TaxLineShare> lines) =>
      TaxComponentAllocator.allocate(
        tax: tax,
        lines: lines,
        componentsFor: componentsFor,
        fallback: defaultSlab != null && defaultSlab!.components.isNotEmpty
            ? defaultSlab!.components
            : _legacy(),
      );
}
