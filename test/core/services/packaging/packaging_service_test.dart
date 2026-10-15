import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/packaging/packaging_service.dart';
import 'package:pos_application/core/services/packaging/stock_formatter.dart';

void main() {
  const service = PackagingService();
  const formatter = StockFormatter();

  group('baseQtyMilli', () {
    test('whole packages', () {
      expect(service.baseQtyMilli(2000, 24000), 48000);
      expect(service.baseQtyMilli(1000, 6000), 6000);
    });
    test('a base-unit line (factor 1) is unchanged', () {
      expect(service.baseQtyMilli(1500, 1000), 1500);
    });
    test('fractional packages of a 25 kg bag', () {
      expect(service.baseQtyMilli(2500, 25000), 62500);
      expect(service.baseQtyMilli(500, 25000), 12500);
    });
    test('rounds half up once, to a milli-unit', () {
      // 0.001 package x 0.5 base per package = 0.0005 -> 1 milli (half up).
      expect(service.baseQtyMilli(1, 500), 1);
      expect(service.baseQtyMilli(1, 499), 0);
      expect(service.baseQtyMilli(3, 500), 2); // 1.5 -> 2
    });
    test('a factor of zero or less is rejected', () {
      expect(() => service.baseQtyMilli(1000, 0), throwsArgumentError);
      expect(() => service.baseQtyMilli(1000, -1), throwsArgumentError);
    });
  });

  group('packagePriceMinor', () {
    test('derived: base price x factor', () {
      expect(
        service.packagePriceMinor(basePriceMinor: 1000, factorMilli: 24000),
        24000,
      );
    });
    test('derived rounds half up once', () {
      // 333 x 6.5 = 2164.5 -> 2165
      expect(
        service.packagePriceMinor(basePriceMinor: 333, factorMilli: 6500),
        2165,
      );
      // 1 x 0.499 = 0.499 -> 0
      expect(service.packagePriceMinor(basePriceMinor: 1, factorMilli: 499), 0);
    });
    test('a large amount stays exact (no double)', () {
      expect(
        service.packagePriceMinor(
          basePriceMinor: 9007199254740993,
          factorMilli: 3000,
        ),
        9007199254740993 * 3,
      );
    });
    test('an explicit price wins over the derived one', () {
      expect(
        service.packagePriceMinor(
          basePriceMinor: 1000,
          factorMilli: 24000,
          explicitMinor: 21000,
        ),
        21000,
      );
      expect(
        service.packagePriceMinor(
          basePriceMinor: 1000,
          factorMilli: 24000,
          explicitMinor: 0,
        ),
        0,
      );
    });
  });

  group('unitOffForPackaging', () {
    test('scales a per-base-unit reduction by the factor', () {
      expect(service.unitOffForPackaging(50, 24000), 1200);
      expect(service.unitOffForPackaging(50, 1000), 50);
      expect(service.unitOffForPackaging(5, 500), 3); // 2.5 -> 3
    });
  });

  group('StockFormatter', () {
    const levels = [
      StockLevel(name: 'Pack', quantityBaseMilli: 6000),
      StockLevel(name: 'Carton', quantityBaseMilli: 24000),
    ];

    test('3 cartons + 5 pcs', () {
      final b = formatter.breakdown(77000, levels, baseUnitName: 'pcs');
      expect(b.negative, isFalse);
      expect(b.parts, const [
        StockPart(name: 'Carton', quantityMilli: 3000, isBase: false),
        StockPart(name: 'pcs', quantityMilli: 5000, isBase: true),
      ]);
    });
    test('cartons, packs and pieces', () {
      final b = formatter.breakdown(80000, levels, baseUnitName: 'pcs');
      expect(b.parts.map((p) => '${p.name}:${p.quantityMilli}'), [
        'Carton:3000',
        'Pack:1000',
        'pcs:2000',
      ]);
    });
    test('exact multiple has no base remainder', () {
      final b = formatter.breakdown(48000, levels, baseUnitName: 'pcs');
      expect(b.parts, const [
        StockPart(name: 'Carton', quantityMilli: 2000, isBase: false),
      ]);
    });
    test('fractional kg keeps its fraction in the base unit', () {
      final b = formatter.breakdown(60500, const [
        StockLevel(name: 'Bag', quantityBaseMilli: 25000),
      ], baseUnitName: 'kg');
      expect(b.parts, const [
        StockPart(name: 'Bag', quantityMilli: 2000, isBase: false),
        StockPart(name: 'kg', quantityMilli: 10500, isBase: true),
      ]);
    });
    test('below the smallest package, zero and no packagings', () {
      expect(
        formatter.breakdown(5000, levels, baseUnitName: 'pcs').parts,
        const [StockPart(name: 'pcs', quantityMilli: 5000, isBase: true)],
      );
      expect(formatter.breakdown(0, levels, baseUnitName: 'pcs').parts, const [
        StockPart(name: 'pcs', quantityMilli: 0, isBase: true),
      ]);
      expect(
        formatter.breakdown(7000, const [], baseUnitName: 'pcs').parts,
        const [StockPart(name: 'pcs', quantityMilli: 7000, isBase: true)],
      );
    });
    test('negative stock formats its absolute value and says so', () {
      final b = formatter.breakdown(-30000, levels, baseUnitName: 'pcs');
      expect(b.negative, isTrue);
      expect(b.parts, const [
        StockPart(name: 'Carton', quantityMilli: 1000, isBase: false),
        StockPart(name: 'Pack', quantityMilli: 1000, isBase: false),
      ]);
    });
    test('input order and a zero-size level do not matter', () {
      final b = formatter.breakdown(30000, const [
        StockLevel(name: 'Zero', quantityBaseMilli: 0),
        StockLevel(name: 'Pack', quantityBaseMilli: 6000),
        StockLevel(name: 'Carton', quantityBaseMilli: 24000),
      ], baseUnitName: 'pcs');
      expect(b.parts.map((p) => p.name), ['Carton', 'Pack']);
    });
  });
}
