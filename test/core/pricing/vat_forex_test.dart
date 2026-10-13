import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/pricing_helpers.dart';
import 'package:pos_application/core/services/pricing/pricing_models.dart';
import 'package:pos_application/core/services/pricing/pricing_service.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/pricing/tax_config.dart';
import 'package:pos_application/core/services/pricing/tax_split.dart';

/// Our own vectors (hand computed, not from React): a VAT store (Uganda, UGX,
/// no minor digits, slabs 0 and 18 %) in both price modes, and forex.
void main() {
  const ugx = CurrencyRegistry.ugx;
  const vat = TaxConfig(
    country: 'UG',
    currency: ugx,
    label: 'VAT',
    mode: TaxMode.exclusive,
    slabsBp: <Bp>[Bp(0), Bp(1800)],
  );
  const exclusive = PricingService(config: vat);
  final inclusive = PricingService(
    config: vat.copyWith(mode: TaxMode.inclusive),
  );

  LineInput line(int price, int qtyMilli, int rateBp, {int discountBp = 0}) =>
      LineInput(
        qty: Qty(qtyMilli),
        price: Money(price, ugx),
        discount: Bp(discountBp),
        taxRate: Bp(rateBp),
      );

  group('VAT store (UGX, exponent 0)', () {
    test('exclusive: 10,000 at 18% adds 1,800', () {
      final t = exclusive.calculate(
        CartInput(lines: [line(10000, 1000, 1800)]),
      );
      expect(t.tax.minor, 1800);
      expect(t.total.minor, 11800);
    });

    test('inclusive: 11,800 at 18% contains 1,800 and totals 11,800', () {
      final t = inclusive.calculate(
        CartInput(lines: [line(11800, 1000, 1800)]),
      );
      expect(t.tax.minor, 1800);
      expect(t.total.minor, 11800);
    });

    test('exclusive multi-slab: zero-rated and standard lines', () {
      final t = exclusive.calculate(
        CartInput(lines: [line(5000, 1000, 0), line(10000, 3000, 1800)]),
      );
      expect(t.value.minor, 35000);
      expect(t.tax.minor, 5400);
      expect(t.total.minor, 40400);
    });

    test('exclusive with a 10% bill discount taxes the discounted lines', () {
      final t = exclusive.calculate(
        CartInput(
          lines: [line(5000, 1000, 0), line(10000, 3000, 1800)],
          billDiscount: const BillDiscount.percent(Bp(1000)),
        ),
      );
      expect(t.tax.minor, 4860);
      expect(t.total.minor, 36360);
    });

    test('inclusive multi-slab: tax is only informational', () {
      final t = inclusive.calculate(
        CartInput(lines: [line(5000, 1000, 0), line(11800, 1000, 1800)]),
      );
      expect(t.total.minor, 16800);
      expect(t.tax.minor, 1800);
    });

    test('a store with no regime applies no tax to any product', () {
      const none = TaxConfig.none;
      final t = PricingService(config: none.copyWith(currency: ugx)).calculate(
        CartInput(
          lines: [line(10000, 1000, none.rateFor(const Bp(1800)).value)],
        ),
      );
      expect(t.tax.minor, 0);
      expect(t.total.minor, 10000);
    });
  });

  group('forex conversion (rate scaled by 1e6, rounded once)', () {
    int fx(Money total, String code, int rateMicro) =>
        PricingHelpers.forexConvert(
          total: total,
          foreign: CurrencyRegistry.byCode(code),
          rateMicro: rateMicro,
        );
    const inr = CurrencyRegistry.inr;

    test('INR into USD, EUR and AED', () {
      const total = Money(100000, inr); // 1,000.00
      expect(fx(total, 'USD', 83200000), 1202); // 12.0192
      expect(fx(total, 'EUR', 90500000), 1105); // 11.0497
      expect(fx(total, 'AED', 22650000), 4415); // 44.1501
    });

    test('UGX (exponent 0) into USD and KES', () {
      const total = Money(1000000, ugx);
      expect(fx(total, 'USD', 3700000000), 27027); // 270.27
      expect(fx(const Money(100000, ugx), 'KES', 28500000), 350877);
    });

    test('a foreign currency with no minor digits', () {
      expect(fx(const Money(100000, inr), 'UGX', 22500), 44444);
    });

    test('half rounds up once', () {
      expect(fx(const Money(150, inr), 'UGX', 1000000), 2);
      expect(fx(const Money(149, inr), 'UGX', 1000000), 1);
    });

    test('a rate of zero or less gives zero', () {
      expect(fx(const Money(100000, inr), 'USD', 0), 0);
      expect(fx(const Money(100000, inr), 'USD', -5), 0);
    });
  });

  group('tax split', () {
    const inr = CurrencyRegistry.inr;
    List<int> split(int minor, List<String> parts) => [
      for (final p in TaxSplit.parts(Money(minor, inr), parts)) p.amount.minor,
    ];

    test('even amounts split in halves', () {
      expect(split(498, ['CGST', 'SGST']), [249, 249]);
    });

    test('an odd minor unit goes to the last part', () {
      expect(split(499, ['CGST', 'SGST']), [249, 250]);
      expect(split(1, ['CGST', 'SGST']), [0, 1]);
    });

    test('no parts means one line (no split)', () {
      expect(TaxSplit.parts(const Money(499, inr), const []), isEmpty);
    });

    test('the parts always add up to the tax', () {
      for (var tax = 0; tax < 500; tax++) {
        for (final n in [1, 2, 3]) {
          final parts = split(tax, [for (var i = 0; i < n; i++) 'P$i']);
          expect(parts.fold<int>(0, (a, b) => a + b), tax);
        }
      }
    });
  });
}
