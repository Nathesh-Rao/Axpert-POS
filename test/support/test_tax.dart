import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/pricing_service.dart';
import 'package:pos_application/core/services/pricing/tax_config.dart';
import 'package:pos_application/features/session/domain/entities/session_entities.dart';

/// India GST (exclusive, slabs 0/5/12/18, CGST + SGST): the tax setup the
/// existing tests and goldens run with. Test support only: `lib/` has no tax
/// defaults, the real rows come from the database.
const TaxConfig testIndiaTax = TaxConfig(
  country: 'IN',
  currency: CurrencyRegistry.inr,
  label: 'GST',
  mode: TaxMode.exclusive,
  slabsBp: <Bp>[Bp(0), Bp(500), Bp(1200), Bp(1800)],
  splitParts: <String>['CGST', 'SGST'],
);

const PricingService testIndiaPricing = PricingService(config: testIndiaTax);

/// The same India setup as database rows (what `ActiveSession` loads).
const TaxRegimeInfo testIndiaRegime = TaxRegimeInfo(
  region: 'IN',
  label: 'GST',
  inclusive: false,
  splitParts: <String>['CGST', 'SGST'],
  slabs: <TaxSlabInfo>[
    TaxSlabInfo(rateBp: 0),
    TaxSlabInfo(rateBp: 500),
    TaxSlabInfo(rateBp: 1200),
    TaxSlabInfo(rateBp: 1800),
  ],
);

/// A Uganda VAT regime (single line, 0 and 18 %).
const TaxRegimeInfo testVatRegime = TaxRegimeInfo(
  region: 'UG',
  label: 'VAT',
  inclusive: false,
  slabs: <TaxSlabInfo>[TaxSlabInfo(rateBp: 0), TaxSlabInfo(rateBp: 1800)],
);

/// Forex rows of the default test store (rate 8.561, as the prototype).
const List<ForexRate> testForex = <ForexRate>[
  ForexRate(code: 'USD', rateMicro: 8561000),
  ForexRate(code: 'EUR', rateMicro: 8561000),
  ForexRate(code: 'AED', rateMicro: 8561000),
];
