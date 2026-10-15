// DEC-151: units, brands, packagings and barcodes (Drift and Mock).
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/database/tables/unit_entries.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/features/products/data/repositories/drift_packaging_repositories.dart';
import 'package:pos_application/features/products/data/repositories/mock_packaging_repositories.dart';
import 'package:pos_application/features/products/domain/entities/packaging_entities.dart';
import 'package:pos_application/features/products/domain/repositories/packaging_repositories.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  final AxpertDatabase db;

  @override
  Future<AxpertDatabase> open() async => db;

  @override
  Future<void> close() async {}
}

ProductPackaging _pack(
  String id,
  String product,
  String unit,
  int qty, {
  int? price,
  bool enabled = true,
}) => ProductPackaging(
  id: id,
  productId: product,
  unitId: unit,
  name: id,
  quantityBaseMilli: qty,
  priceMinor: price,
  enabled: enabled,
);

/// The behavior both implementations share.
void _contract(
  String name,
  Future<
    ({
      UnitRepository units,
      BrandRepository brands,
      PackagingRepository packagings,
      BarcodeRepository barcodes,
    })
  >
  Function()
  make,
) {
  group(name, () {
    late UnitRepository units;
    late BrandRepository brands;
    late PackagingRepository packagings;
    late BarcodeRepository barcodes;

    setUp(() async {
      MockDelay.provider = () => Duration.zero;
      final r = await make();
      units = r.units;
      brands = r.brands;
      packagings = r.packagings;
      barcodes = r.barcodes;
    });

    test('the eight standard units', () async {
      expect((await units.all()).map((u) => u.code).toSet(), {
        'piece',
        'pack',
        'carton',
        'box',
        'kg',
        'g',
        'litre',
        'ml',
      });
      final kg = await units.byCode('kg');
      expect(kg!.kind, UnitKind.weight);
      expect(kg.id, SeedUnits.kg.id);
      expect(await units.byCode('dozen'), isNull);
    });

    test('brands: save, rename, tombstone', () async {
      await brands.save(const Brand(id: 'b1', name: 'Zed'));
      await brands.save(const Brand(id: 'b2', name: 'Acme'));
      expect((await brands.all()).map((b) => b.name), ['Acme', 'Zed']);
      await brands.save(const Brand(id: 'b1', name: 'Yak'));
      expect((await brands.all()).map((b) => b.name), ['Acme', 'Yak']);
      await brands.remove('b2');
      expect((await brands.all()).map((b) => b.id), ['b1']);
    });

    test(
      'packagings: list by sort order, update, unique unit, tombstone',
      () async {
        await packagings.save(_pack('c', 'p1', SeedUnits.carton.id, 24000));
        await packagings.save(_pack('k', 'p1', SeedUnits.pack.id, 6000));
        await packagings.save(_pack('x', 'p2', SeedUnits.pack.id, 4000));
        // Same sort order (0): the smaller package first.
        expect((await packagings.forProduct('p1')).map((p) => p.id), [
          'k',
          'c',
        ]);

        await packagings.save(
          _pack('k', 'p1', SeedUnits.pack.id, 12000, price: 5500),
        );
        final k = (await packagings.forProduct(
          'p1',
        )).firstWhere((p) => p.id == 'k');
        expect((k.quantityBaseMilli, k.priceMinor), (12000, 5500));

        await expectLater(
          packagings.save(_pack('dup', 'p1', SeedUnits.carton.id, 1000)),
          throwsA(isA<DuplicatePackagingException>()),
        );
        expect(await packagings.forProduct('p1'), hasLength(2));

        // A removed level frees the unit again.
        await packagings.remove('c');
        expect((await packagings.forProduct('p1')).map((p) => p.id), ['k']);
        await packagings.save(_pack('c2', 'p1', SeedUnits.carton.id, 24000));
        expect(await packagings.forProduct('p1'), hasLength(2));
        expect(await packagings.forProduct('p2'), hasLength(1));
      },
    );

    test('barcodes: unique per store scope, tombstone frees it', () async {
      Future<void> save(
        String id,
        String code, {
        String? store,
        String? pack,
      }) => barcodes.save(
        ProductBarcode(
          id: id,
          productId: 'p1',
          barcode: code,
          storeId: store,
          packagingId: pack,
        ),
      );
      await save('a', 'X1', store: 's1');
      await expectLater(
        save('b', 'X1', store: 's1'),
        throwsA(isA<DuplicateBarcodeException>()),
      );
      await save('c', 'X1', store: 's2'); // another store
      await save('d', 'X1'); // the shared scope
      await expectLater(
        save('e', 'X1'),
        throwsA(isA<DuplicateBarcodeException>()),
      );
      await save('a', 'X1', store: 's1'); // updating itself is fine
      expect((await barcodes.forProduct('p1')).map((b) => b.id).toSet(), {
        'a',
        'c',
        'd',
      });
      await barcodes.remove('a');
      await save('f', 'X1', store: 's1');
      expect((await barcodes.forProduct('p1')), hasLength(3));
    });
  });
}

void main() {
  _contract('Mock', () async {
    final store = InMemoryLocalStore();
    return (
      units: const MockUnitRepository(),
      brands: MockBrandRepository(store),
      packagings: MockPackagingRepository(store),
      barcodes: MockBarcodeRepository(store),
    );
  });

  late AxpertDatabase db;
  _contract('Drift', () async {
    db = AxpertDatabase(NativeDatabase.memory());
    await db.customStatement(
      "INSERT INTO currencies (code, name, symbol, exponent, grouping, "
      "created_at, updated_at) VALUES ('INR', 'R', 'R', 2, 'lakh', 1, 1)",
    );
    for (final s in ['s1', 's2']) {
      await db.customStatement(
        'INSERT INTO stores (id, name, currency_code, created_at, updated_at) '
        "VALUES ('$s', '$s', 'INR', 1, 1)",
      );
    }
    for (final (i, p) in ['p1', 'p2'].indexed) {
      await db.customStatement(
        'INSERT INTO products (id, legacy_id, position, name, code, barcode, '
        'price_minor, category, sub, stock, gst_bp, image, favourite, '
        "created_at, updated_at) VALUES ('$p', ${i + 1}, $i, 'n', 'c', '', "
        "100, 'c', 's', 0, 0, -1, 0, 1, 1)",
      );
    }
    final provider = _Provider(db);
    var tick = 1000;
    int now() => tick++;
    return (
      units: DriftUnitRepository(provider),
      brands: DriftBrandRepository(provider, now: now),
      packagings: DriftPackagingRepository(provider, now: now),
      barcodes: DriftBarcodeRepository(provider, now: now),
    );
  });
  tearDown(() async {
    try {
      await db.close();
    } on Object {
      // The Mock group has no database.
    }
  });

  group('findByBarcode (Drift)', () {
    late DriftBarcodeRepository barcodes;
    late DriftPackagingRepository packagings;

    setUp(() async {
      db = AxpertDatabase(NativeDatabase.memory());
      await db.customStatement(
        "INSERT INTO currencies (code, name, symbol, exponent, grouping, "
        "created_at, updated_at) VALUES ('INR', 'R', 'R', 2, 'lakh', 1, 1)",
      );
      for (final s in ['s1', 's2']) {
        await db.customStatement(
          'INSERT INTO stores (id, name, currency_code, created_at, '
          "updated_at) VALUES ('$s', '$s', 'INR', 1, 1)",
        );
      }
      Future<void> product(String id, int legacy, String store, int? del) =>
          db.customStatement(
            'INSERT INTO products (id, legacy_id, position, name, code, '
            'barcode, price_minor, category, sub, stock, gst_bp, image, '
            'favourite, store_id, created_at, updated_at, deleted_at) VALUES '
            "('$id', $legacy, $legacy, 'n', 'c$legacy', '', 100, 'c', 's', 0, "
            "0, -1, 0, '$store', 1, 1, ${del ?? 'NULL'})",
          );
      await product('p1', 1, 's1', null);
      await product('p2', 2, 's2', null);
      await product('gone', 3, 's1', 5);
      final provider = _Provider(db);
      barcodes = DriftBarcodeRepository(provider);
      packagings = DriftPackagingRepository(provider);
      await packagings.save(_pack('c24', 'p1', SeedUnits.carton.id, 24000));
      await packagings.save(
        _pack('off', 'p1', SeedUnits.box.id, 12000, enabled: false),
      );
      Future<void> code(
        String id,
        String product,
        String code,
        String store, {
        String? pack,
      }) => barcodes.save(
        ProductBarcode(
          id: id,
          productId: product,
          barcode: code,
          storeId: store,
          packagingId: pack,
        ),
      );
      await code('b1', 'p1', '111', 's1');
      await code('b2', 'p1', '222', 's1', pack: 'c24');
      await code('b3', 'p1', '333', 's1', pack: 'off');
      await code('b4', 'p2', '111', 's2'); // same code, other store
      await code('b5', 'gone', '999', 's1');
    });

    test(
      'a base code finds the product, a carton code its packaging',
      () async {
        final base = await barcodes.findByBarcode('s1', '111');
        expect(base!.productId, 'p1');
        expect(base.productLegacyId, 1);
        expect(base.packaging, isNull);

        final carton = await barcodes.findByBarcode('s1', '222');
        expect(carton!.packaging!.id, 'c24');
        expect(carton.packaging!.quantityBaseMilli, 24000);
      },
    );

    test('the store scope decides who owns a shared code', () async {
      expect((await barcodes.findByBarcode('s2', '111'))!.productId, 'p2');
      expect((await barcodes.findByBarcode('s1', '111'))!.productId, 'p1');
      expect(await barcodes.findByBarcode('s2', '222'), isNull);
      // No store (unscoped session): any live row.
      expect(await barcodes.findByBarcode(null, '222'), isNotNull);
    });

    test('a disabled packaging is still reported, flagged', () async {
      final m = await barcodes.findByBarcode('s1', '333');
      expect(m!.packaging!.enabled, isFalse);
    });

    test('unknown, removed and deleted-product codes find nothing', () async {
      expect(await barcodes.findByBarcode('s1', 'nope'), isNull);
      expect(await barcodes.findByBarcode('s1', '999'), isNull);
      await barcodes.remove('b1');
      expect(await barcodes.findByBarcode('s1', '111'), isNull);
      // A code of a removed packaging must not sell the base unit.
      await packagings.remove('c24');
      expect(await barcodes.findByBarcode('s1', '222'), isNull);
    });
  });
}
