// Tax components: the allocator splits the already rounded tax across
// components, sums exactly, and equals the legacy equal split for 1 and 2
// components (byte-identical output for today's stores).
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/pricing_models.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/pricing/rational.dart';
import 'package:pos_application/core/services/pricing/tax_components.dart';
import 'package:pos_application/core/services/pricing/tax_split.dart';
import 'package:pos_application/features/session/domain/entities/session_entities.dart';

import '../../support/test_tax.dart';

Money _inr(int minor) => Money(minor, CurrencyRegistry.inr);

List<int> _minors(List<TaxPart> parts) => [
  for (final p in parts) p.amount.minor,
];

void main() {
  group('legacy regime (CGST + SGST equal split)', () {
    test('equals TaxSplit for every tax amount and any line mix', () {
      for (var tax = 0; tax <= 300; tax++) {
        final expected = TaxSplit.parts(_inr(tax), const ['CGST', 'SGST']);
        // One line, and the same tax spread over lines of different rates.
        final single = testIndiaRegime.partsOf(_inr(tax), [
          TaxLineShare(tax: Rational.fromInt(tax), rateBp: 1800),
        ]);
        final mixed = testIndiaRegime.partsOf(_inr(tax), [
          TaxLineShare(
            tax: Rational.fromInt(tax) / Rational.fromInt(3),
            rateBp: 500,
          ),
          TaxLineShare(
            tax:
                Rational.fromInt(tax) *
                Rational.fromInt(2) /
                Rational.fromInt(3),
            rateBp: 1200,
          ),
        ]);
        expect(single, expected, reason: 'tax $tax');
        expect(mixed, expected, reason: 'tax $tax mixed');
      }
    });

    test('an empty cart still lists CGST and SGST at zero', () {
      final parts = testIndiaRegime.partsOf(_inr(0), const []);
      expect([for (final p in parts) p.label], ['CGST', 'SGST']);
      expect(_minors(parts), [0, 0]);
    });

    test('a VAT regime has one component (no split rows)', () {
      final parts = testVatRegime.partsOf(_inr(180), [
        TaxLineShare(tax: Rational.fromInt(180), rateBp: 1800),
      ]);
      expect(parts, hasLength(1));
      expect(parts.single.label, 'VAT');
      expect(parts.single.amount.minor, 180);
    });
  });

  group('component slabs', () {
    final gst = TaxSlabInfo.of(
      id: 'a',
      name: 'GST 18%',
      isDefault: true,
      components: const [
        TaxComponent(label: 'CGST', rateBp: 900),
        TaxComponent(label: 'SGST', rateBp: 900),
      ],
    );
    final vatService = TaxSlabInfo.of(
      id: 'b',
      name: 'VAT 16% + Service 5%',
      components: const [
        TaxComponent(label: 'VAT', rateBp: 1600),
        TaxComponent(label: 'Service charge', rateBp: 500),
      ],
    );
    final three = TaxSlabInfo.of(
      id: 'c',
      name: 'Three',
      components: const [
        TaxComponent(label: 'A', rateBp: 100),
        TaxComponent(label: 'B', rateBp: 100),
        TaxComponent(label: 'C', rateBp: 100),
      ],
    );

    test('slab total is the sum of enabled components in basis points', () {
      expect(gst.rateBp, 1800);
      expect(vatService.rateBp, 2100);
      final off = TaxSlabInfo.of(
        id: 'd',
        name: 'x',
        components: const [
          TaxComponent(label: 'A', rateBp: 300),
          TaxComponent(label: 'B', rateBp: 200, enabled: false),
        ],
      );
      expect(off.rateBp, 300);
    });

    test('unequal components are weighted by rate and sum exactly', () {
      final regime = TaxRegimeInfo(
        region: 'XX',
        label: '',
        inclusive: false,
        slabs: [vatService],
      );
      // 1000.00 at 21% = 210.00: VAT 160.00, Service charge 50.00.
      final parts = regime.partsOf(_inr(21000), [
        TaxLineShare(tax: Rational.fromInt(21000), rateBp: 2100),
      ]);
      expect([for (final p in parts) p.label], ['VAT', 'Service charge']);
      expect(_minors(parts), [16000, 5000]);
    });

    test('three components: parts add up for every tax amount', () {
      final regime = TaxRegimeInfo(
        region: 'XX',
        label: '',
        inclusive: false,
        slabs: [three],
      );
      for (var tax = 0; tax <= 100; tax++) {
        final parts = regime.partsOf(_inr(tax), [
          TaxLineShare(tax: Rational.fromInt(tax), rateBp: 300),
        ]);
        expect(parts, hasLength(3));
        expect(_minors(parts).reduce((a, b) => a + b), tax);
      }
      // The odd units go to the last components, like the equal split.
      expect(
        _minors(
          regime.partsOf(_inr(2), [
            TaxLineShare(tax: Rational.fromInt(2), rateBp: 300),
          ]),
        ),
        [0, 1, 1],
      );
    });

    test('lines of two slabs merge components with the same label', () {
      final regime = TaxRegimeInfo(
        region: 'XX',
        label: '',
        inclusive: false,
        slabs: [gst, vatService],
      );
      final parts = regime.partsOf(_inr(390), [
        TaxLineShare(tax: Rational.fromInt(180), rateBp: 1800),
        TaxLineShare(tax: Rational.fromInt(210), rateBp: 2100),
      ]);
      expect(
        [for (final p in parts) p.label],
        ['CGST', 'SGST', 'VAT', 'Service charge'],
      );
      expect(_minors(parts), [90, 90, 160, 50]);
    });

    test('a rate with no slab falls back to the regime label', () {
      final regime = TaxRegimeInfo(
        region: 'XX',
        label: 'Tax',
        inclusive: false,
        slabs: [gst],
      );
      final parts = regime.partsOf(_inr(70), [
        TaxLineShare(tax: Rational.fromInt(70), rateBp: 700),
      ]);
      expect(parts, hasLength(1));
      expect(parts.single.amount.minor, 70);
    });

    test('real pricing: tax of a mixed cart is shared exactly', () {
      final regime = TaxRegimeInfo(
        region: 'XX',
        label: '',
        inclusive: false,
        slabs: [gst, vatService],
      );
      final cart = CartInput(
        lines: [
          LineInput(
            qty: const Qty(3000),
            price: _inr(3333),
            taxRate: const Bp(1800),
          ),
          LineInput(
            qty: const Qty(1000),
            price: _inr(999),
            taxRate: const Bp(2100),
          ),
        ],
      );
      final service = testIndiaPricing;
      final totals = service.calculate(cart);
      final parts = regime.partsOf(totals.tax, [
        for (var i = 0; i < 2; i++)
          TaxLineShare(
            tax: totals.exact.lines[i].tax,
            rateBp: cart.lines[i].taxRate.value,
          ),
      ]);
      expect(_minors(parts).reduce((a, b) => a + b), totals.tax.minor);
    });
  });

  group('slab lookup', () {
    test('legacy tiebreak: default slab first, then position', () {
      const a = TaxSlabInfo(rateBp: 500, label: 'first');
      const b = TaxSlabInfo(rateBp: 500, label: 'second', isDefault: true);
      const c = TaxSlabInfo(rateBp: 500, label: 'third');
      const regime = TaxRegimeInfo(
        region: 'XX',
        label: 'T',
        inclusive: false,
        slabs: [a, b, c],
      );
      expect(regime.slabFor(500)!.label, 'second');
      const noDefault = TaxRegimeInfo(
        region: 'XX',
        label: 'T',
        inclusive: false,
        slabs: [a, c],
      );
      expect(noDefault.slabFor(500)!.label, 'first');
    });

    test('disabled and inter-state slabs never price a standard line', () {
      const off = TaxSlabInfo(rateBp: 500, label: 'off', enabled: false);
      const igst = TaxSlabInfo(
        rateBp: 500,
        label: 'igst',
        scheme: TaxScheme.interState,
      );
      const regime = TaxRegimeInfo(
        region: 'XX',
        label: 'T',
        inclusive: false,
        slabs: [off, igst],
      );
      expect(regime.slabFor(500), isNull);
      expect(regime.slabFor(500, scheme: TaxScheme.interState)!.label, 'igst');
    });

    test('tax name: legacy label, one component, or empty for several', () {
      expect(testIndiaRegime.taxName, 'GST');
      final one = TaxRegimeInfo(
        region: 'XX',
        label: 'GST',
        inclusive: false,
        slabs: [
          TaxSlabInfo.of(
            id: 'v',
            name: 'VAT 18%',
            isDefault: true,
            components: const [TaxComponent(label: 'VAT', rateBp: 1800)],
          ),
        ],
      );
      expect(one.taxName, 'VAT');
      final two = TaxRegimeInfo(
        region: 'XX',
        label: 'GST',
        inclusive: false,
        slabs: [
          TaxSlabInfo.of(
            id: 'g',
            name: 'GST 18%',
            isDefault: true,
            components: const [
              TaxComponent(label: 'CGST', rateBp: 900),
              TaxComponent(label: 'SGST', rateBp: 900),
            ],
          ),
        ],
      );
      expect(two.taxName, '');
    });
  });
}
