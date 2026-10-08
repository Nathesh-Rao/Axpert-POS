import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/mock/seed_customers.dart';
import 'package:pos_application/core/mock/seed_products.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';

/// The mock data must equal `reference_react/src/data.ts`.
void main() {
  final products = SeedProducts.products();

  test('20 products, ids 0..19, 12 images and 8 placeholders', () {
    expect(products.length, 20);
    expect(products.map((p) => p.id), List<int>.generate(20, (i) => i));
    expect(products.where((p) => p.hasImage).length, 12);
    expect(products.where((p) => !p.hasImage).length, 8);
    expect(
      products.take(12).map((p) => p.image),
      List<int>.generate(12, (i) => i),
    );
  });

  test('names, codes, prices, categories', () {
    final p5 = products[5];
    expect(
      (p5.name, p5.code, p5.price.minor, p5.category, p5.sub),
      ('Lays Classic 52g', 'CHP001', 2000, 'Snacks', 'Chips'),
    );
    final p19 = products[19];
    expect(
      (p19.name, p19.code, p19.price.minor, p19.category, p19.sub),
      ('Himalaya Shampoo 200ml', 'PER005', 15500, 'Personal Care', 'Hair Care'),
    );
  });

  test('barcodes, stock, gst, favourites', () {
    expect(products[0].barcode, '8901234567890');
    expect(products[9].barcode, '8901234567899');
    expect(products[10].barcode, '8901234567800');
    expect(products[19].barcode, '8901234567809');
    expect(products[0].stock, 45);
    expect(products[14].stock, 8);
    expect(products[19].stock, 45 + 19 * 3);
    expect(products.map((p) => p.gst.value ~/ 100).take(6), [
      18,
      12,
      5,
      18,
      12,
      5,
    ]);
    expect(products[5].gst, const Bp(500));
    expect(products.where((p) => p.favourite).map((p) => p.id), [0, 5, 8]);
  });

  test('4 customers', () {
    final c = SeedCustomers.customers;
    expect(c.map((e) => e.id), ['walk', '1', '2', '3']);
    expect(c.map((e) => e.points), [0, 250, 120, 400]);
    expect(c[1].member, 'MG1001');
    expect(c[0].isWalkIn, isTrue);
  });
}
