// DEC-151: ProductRows keeps the base-unit barcode row in product_barcodes
// equal to the products.barcode cache.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/migration/product_rows.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/features/products/domain/entities/product.dart';

import '../../support/product_fixtures.dart';

void main() {
  late AxpertDatabase db;
  final uuid = UuidV4Generator();

  setUp(() => db = AxpertDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> save(List<Product> list) async {
    final read = await ProductRows.read(db);
    final plan = ProductRows.plan(list, read.known, now: 5, uuid: uuid);
    await db.durableTransaction(() => ProductRows.write(db, plan, now: 5));
  }

  Future<List<(String, bool)>> rows() async => [
    for (final r
        in await db
            .customSelect(
              'SELECT barcode, deleted_at FROM product_barcodes ORDER BY barcode',
            )
            .get())
      (r.read<String>('barcode'), r.read<int?>('deleted_at') != null),
  ];

  test('new, changed and removed products move their base barcode', () async {
    await save([
      prod(1, barcode: 'A'),
      prod(2, barcode: 'B'),
      prod(3, barcode: ''),
    ]);
    expect(await rows(), [('A', false), ('B', false)]);

    // A barcode edit tombstones the old row and adds the new one.
    await save([
      prod(1, barcode: 'A2'),
      prod(2, barcode: 'B'),
      prod(3, barcode: ''),
    ]);
    expect(await rows(), [('A', true), ('A2', false), ('B', false)]);

    // A stock-only change writes the product but touches no barcode row.
    await save([
      prod(1, barcode: 'A2', stock: 3),
      prod(2, barcode: 'B'),
      prod(3, barcode: ''),
    ]);
    expect(await rows(), [('A', true), ('A2', false), ('B', false)]);

    // A removed product tombstones its barcode.
    await save([prod(1, barcode: 'A2'), prod(3, barcode: '')]);
    expect(await rows(), [('A', true), ('A2', false), ('B', true)]);
  });

  test('a barcode already used in the same scope is not written twice', () async {
    await save([prod(1, barcode: 'A'), prod(2, barcode: 'A')]);
    // The cache column keeps both (A3); the table keeps the first owner.
    expect(await rows(), [('A', false)]);
    final owner = await db
        .customSelect(
          'SELECT p.legacy_id AS id FROM product_barcodes b JOIN products p ON p.id = b.product_id',
        )
        .getSingle();
    expect(owner.read<int>('id'), 1);
  });

  test('a big batch (set-based path) gives the same result', () async {
    List<Product> list(int n, {int? change}) => [
      for (var i = 1; i <= n; i++)
        prod(i, barcode: i == change ? 'NEW' : (i == 2 ? 'B1' : 'B$i')),
    ];
    await save(list(600));
    // 600 live codes: product 2 repeats B1 (product 1 keeps it).
    expect(await rows(), hasLength(599));
    final owner = await db
        .customSelect(
          'SELECT p.legacy_id AS id FROM product_barcodes b JOIN products p '
          "ON p.id = b.product_id WHERE b.barcode = 'B1'",
        )
        .getSingle();
    expect(owner.read<int>('id'), 1);

    // 600 products again with one new code, 599 products dropped.
    await save(list(600, change: 5));
    final live = [
      for (final r in await rows())
        if (!r.$2) r.$1,
    ];
    expect(live, contains('NEW'));
    expect(live, isNot(contains('B5')));
    expect(live, hasLength(599));

    await save([prod(1, barcode: 'B1')]);
    // Fewer than a batch now: the per-product path keeps the one row.
    final left = [
      for (final r in await rows())
        if (!r.$2) r.$1,
    ];
    expect(left, ['B1']);
  });
}
