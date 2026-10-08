import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/decimal_parser.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/utils/money_formatter.dart';

void main() {
  group('Money', () {
    test('arithmetic and comparison in one currency', () {
      const a = Money(1050, CurrencyRegistry.inr);
      const b = Money(250, CurrencyRegistry.inr);
      expect((a + b).minor, 1300);
      expect((a - b).minor, 800);
      expect(a > b, isTrue);
      expect((-a).minor, -1050);
    });

    test('cross-currency arithmetic throws', () {
      const a = Money(100, CurrencyRegistry.inr);
      const b = Money(100, CurrencyRegistry.usd);
      expect(() => a + b, throwsA(isA<CurrencyMismatch>()));
      expect(() => a - b, throwsA(isA<CurrencyMismatch>()));
      expect(() => a.compareTo(b), throwsA(isA<CurrencyMismatch>()));
      expect(a == b, isFalse);
    });

    test('JSON round trip for every seed currency', () {
      for (final c in CurrencyRegistry.all) {
        final m = Money(-123456, c);
        expect(Money.fromJson(m.toJson()), m);
      }
      expect(() => CurrencyRegistry.byCode('XXX'), throwsArgumentError);
    });

    test('parse uses the currency exponent', () {
      expect(Money.parse('12.5', CurrencyRegistry.inr).minor, 1250);
      expect(Money.parse('12.345', CurrencyRegistry.inr).minor, 1235);
      expect(Money.parse('12.5', CurrencyRegistry.ugx).minor, 13);
      expect(Money.parse('1.2345', CurrencyRegistry.tnd).minor, 1235);
    });
  });

  group('Decimal parsing', () {
    test('qty milli-units and commit rounding', () {
      expect(Qty.parse('1').milli, 1000);
      expect(Qty.parse('0.5').milli, 500);
      expect(Qty.parse('.25').milli, 250);
      expect(Qty.parse('2.0005').milli, 2001);
      expect(Qty.parse('2.0004').milli, 2000);
      expect(Qty.units(3).milli, 3000);
    });

    test('basis points from percent text, no float multiply', () {
      expect(Bp.parsePercent('18').value, 1800);
      expect(Bp.parsePercent('12.5').value, 1250);
      expect(Bp.parsePercent('0.07').value, 7);
      expect(Bp.parsePercent('0.005').value, 1);
      expect(Bp.parsePercent('5').clamp(Bp.zero, Bp.full).value, 500);
      expect(Bp.parsePercent('250').clamp(Bp.zero, Bp.full), Bp.full);
    });

    test('rejects junk and handles negatives', () {
      expect(() => DecimalParser.parseScaled('abc', 2), throwsFormatException);
      expect(() => DecimalParser.parseScaled('', 2), throwsFormatException);
      expect(() => DecimalParser.parseScaled('.', 2), throwsFormatException);
      expect(DecimalParser.parseScaled('-1.005', 2), -100);
      expect(DecimalParser.parseScaled('-0.5', 0), 0);
    });
  });

  group('MoneyFormatter', () {
    String f(int minor, c) => MoneyFormatter.formatMinor(minor, c);

    test('INR uses lakh grouping', () {
      expect(f(12345600, CurrencyRegistry.inr), '₹1,23,456.00');
      expect(f(99999, CurrencyRegistry.inr), '₹999.99');
      expect(f(100000000000, CurrencyRegistry.inr), '₹1,00,00,00,000.00');
    });

    test('every seed currency formats with its exponent and grouping', () {
      const expected = {
        'INR': '₹1,23,456.78',
        'USD': r'$123,456.78',
        'EUR': '€123,456.78',
        'AED': 'AED 123,456.78',
        'KES': 'KSh 123,456.78',
        'NGN': '₦123,456.78',
        'GHS': 'GH₵123,456.78',
        'ZAR': 'R 123,456.78',
        'UGX': 'USh 12,345,678',
        'RWF': 'RF 12,345,678',
        'XOF': 'CFA 12,345,678',
        'TND': 'DT 12,345.678',
      };
      for (final c in CurrencyRegistry.all) {
        expect(f(12345678, c), expected[c.code], reason: c.code);
      }
    });

    test('small values, zero, negatives and no-symbol', () {
      expect(f(5, CurrencyRegistry.inr), '₹0.05');
      expect(f(0, CurrencyRegistry.inr), '₹0.00');
      expect(f(5, CurrencyRegistry.tnd), 'DT 0.005');
      expect(f(7, CurrencyRegistry.ugx), 'USh 7');
      expect(f(-12345, CurrencyRegistry.inr), '-₹123.45');
      expect(
        MoneyFormatter.format(
          const Money(12345600, CurrencyRegistry.inr),
          symbol: false,
        ),
        '1,23,456.00',
      );
    });
  });
}
