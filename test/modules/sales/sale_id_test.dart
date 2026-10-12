// The optional `saleId` (UUID v4) on NEW sales (DEC-123): additive and
// nullable, old stored sales load unchanged and re-serialize without the key.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/modules/returns/services/refund_service.dart';
import 'package:pos_application/modules/sales/models/sale.dart';

import '../../support/sale_fixtures.dart';

Map<String, dynamic> _roundTrip(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  final at = DateTime.utc(2026, 10, 8);

  test('a new sale writes and reads its saleId', () {
    final sale = testSale(number: 'AX000001', at: at, saleId: 'id-1');
    final json = _roundTrip(sale.toJson());
    expect(json['saleId'], 'id-1');
    expect(Sale.fromJson(json).saleId, 'id-1');
  });

  test(
    'without a saleId the key is absent: JSON identical to the old shape',
    () {
      final sale = testSale(number: 'AX000001', at: at, cashier: null);
      final json = _roundTrip(sale.toJson());
      expect(json.containsKey('saleId'), isFalse);
      expect(json.keys, <String>[
        'number',
        'date',
        'store',
        'customer',
        'cart',
        'totals',
        'mode',
        'tenderedMinor',
        'changeMinor',
        'returned',
      ]);
    },
  );

  test('a sale stored before saleId existed loads unchanged and stays so', () {
    final old = _roundTrip(testSale(number: 'AX000002', at: at).toJson());
    final loaded = Sale.fromJson(old);
    expect(loaded.saleId, isNull);
    expect(_roundTrip(loaded.toJson()), old);
  });

  test('copyWith and a refund keep the saleId', () {
    final sale = testSale(number: 'AX000003', at: at, saleId: 'id-3');
    expect(
      sale.copyWith(returned: <int, Qty>{1: const Qty(1000)}).saleId,
      'id-3',
    );
    final refunded = RefundService.applyReturned(sale, <int, Qty>{
      1: const Qty(1000),
    });
    expect(refunded.saleId, 'id-3');
  });
}
