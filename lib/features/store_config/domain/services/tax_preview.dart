import '../../../../core/services/pricing/basis_points.dart';
import '../../../../core/services/pricing/currency.dart';
import '../../../../core/services/pricing/money.dart';
import '../../../../core/services/pricing/pricing_models.dart';
import '../../../../core/services/pricing/pricing_service.dart';
import '../../../../core/services/pricing/qty.dart';
import '../../../../core/services/pricing/tax_components.dart';
import '../../../../core/services/pricing/tax_config.dart';
import '../../../../core/services/pricing/tax_split.dart';
import '../../../session/domain/entities/session_entities.dart';

/// The sample bill of the page: one line at a slab, priced by the real
/// [PricingService] and split by the real allocator, so it shows exactly the
/// tax lines the bill and the receipt print.
class TaxPreview {
  const TaxPreview({
    required this.subtotal,
    required this.tax,
    required this.parts,
    required this.total,
  });

  final Money subtotal;
  final Money tax;

  /// One line per component (empty when the slab has one component).
  final List<TaxPart> parts;
  final Money total;

  /// [priceMinor] is the price of one unit in minor units.
  static TaxPreview of({
    required TaxSlabInfo slab,
    required Currency currency,
    required int priceMinor,
    bool inclusive = false,
  }) {
    final service = PricingService(
      config: TaxConfig(
        country: '',
        currency: currency,
        label: 'tax',
        mode: inclusive ? TaxMode.inclusive : TaxMode.exclusive,
        slabsBp: <Bp>[Bp(slab.rateBp)],
      ),
    );
    final totals = service.calculate(
      CartInput(
        lines: <LineInput>[
          LineInput(
            qty: const Qty(1000),
            price: Money(priceMinor, currency),
            taxRate: Bp(slab.rateBp),
          ),
        ],
      ),
    );
    final parts = TaxComponentAllocator.allocate(
      tax: totals.tax,
      lines: <TaxLineShare>[
        TaxLineShare(tax: totals.exact.lines.single.tax, rateBp: slab.rateBp),
      ],
      componentsFor: (_) => slab.components,
      fallback: slab.components,
    );
    return TaxPreview(
      subtotal: totals.subtotal,
      tax: totals.tax,
      parts: parts.length >= 2 ? parts : const <TaxPart>[],
      total: totals.total,
    );
  }
}
