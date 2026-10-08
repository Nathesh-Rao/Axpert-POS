import 'basis_points.dart';
import 'currency.dart';
import 'currency_registry.dart';

enum TaxMode { exclusive, inclusive }

/// Country-level currency and tax setup. The default (INR + GST exclusive,
/// slabs 0/5/12/18) reproduces the prototype.
class TaxConfig {
  const TaxConfig({
    required this.country,
    required this.currency,
    required this.label,
    required this.mode,
    required this.slabsBp,
  });

  static const TaxConfig india = TaxConfig(
    country: 'IN',
    currency: CurrencyRegistry.inr,
    label: 'GST',
    mode: TaxMode.exclusive,
    slabsBp: [Bp(0), Bp(500), Bp(1200), Bp(1800)],
  );

  final String country;
  final Currency currency;
  final String label;
  final TaxMode mode;
  final List<Bp> slabsBp;

  TaxConfig copyWith({TaxMode? mode}) => TaxConfig(
    country: country,
    currency: currency,
    label: label,
    mode: mode ?? this.mode,
    slabsBp: slabsBp,
  );
}
