import 'basis_points.dart';
import 'currency.dart';
import 'currency_registry.dart';

enum TaxMode { exclusive, inclusive }

/// Currency and tax setup of the active store, built from its tax regime rows
/// (`tax_regimes`, `tax_slabs`). No tax rules live in code: [none] (no label,
/// no slabs) applies zero tax.
class TaxConfig {
  const TaxConfig({
    required this.country,
    required this.currency,
    required this.label,
    required this.mode,
    required this.slabsBp,
    this.splitParts = const <String>[],
  });

  /// No regime: zero tax, no label. The currency is a placeholder until a
  /// store is open (see `copyWith`).
  static const TaxConfig none = TaxConfig(
    country: '',
    currency: CurrencyRegistry.inr,
    label: '',
    mode: TaxMode.exclusive,
    slabsBp: <Bp>[],
  );

  final String country;
  final Currency currency;

  /// Tax name (`GST`, `VAT`); empty when the store has no regime.
  final String label;
  final TaxMode mode;
  final List<Bp> slabsBp;

  /// Components of the total tax (`CGST`, `SGST`); empty = one line.
  final List<String> splitParts;

  bool get hasRegime => label.isNotEmpty;

  /// The rate applied to a product: its own rate under a regime, else zero.
  Bp rateFor(Bp productRate) => hasRegime ? productRate : Bp.zero;

  TaxConfig copyWith({TaxMode? mode, Currency? currency}) => TaxConfig(
    country: country,
    currency: currency ?? this.currency,
    label: label,
    mode: mode ?? this.mode,
    slabsBp: slabsBp,
    splitParts: splitParts,
  );
}
