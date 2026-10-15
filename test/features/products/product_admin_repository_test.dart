// DEC-152: product management writes (Drift, atomic) and the Mock twin.
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/core/session/store_scope.dart';
import 'package:pos_application/features/inventory/data/drift_inventory_repository.dart';
import 'package:pos_application/features/products/data/repositories/drift_product_admin_repository.dart';
import 'package:pos_application/features/products/data/repositories/mock_product_admin_repository.dart';
import 'package:pos_application/features/products/data/repositories/mock_product_repository.dart';
import 'package:pos_application/features/products/domain/entities/packaging_entities.dart';
import 'package:pos_application/features/products/domain/entities/product_admin_entities.dart';
import 'package:pos_application/features/products/domain/repositories/product_admin_repository.dart';

import '../../support/seeded_database.dart';

const _piece = '5a1f0001-0000-4000-8000-000000000001';
const _carton = '5a1f0001-0000-4000-8000-000000000003';
const _pack = '5a1f0001-0000-4000-8000-000000000002';

ProductDraft _draft({
  String name = 'Test Cola',
  String code = 'TST001',
  List<String> barcodes = const ['9990000000001'],
  List<PackagingDraft>? packagings,
  int opening = 77000,
  int price = 10000,
}) => ProductDraft(
  name: name,
  code: code,
  priceMinor: price,
  gstBp: 1800,
  baseUnitId: _piece,
  category: 'Beverages',
  sub: 'Soft Drinks',
  categoryId: 'demo-cat-1',
  barcodes: barcodes,
  packagings:
      packagings ??
      const [
        PackagingDraft(
          unitId: _carton,
          name: 'Carton',
          quantityBaseMilli: 24000,
          barcode: '9990000000024',
        ),
      ],
  openingMilli: opening,
);

Future<int> _count(
  AxpertDatabase db,
  String sql, [
  List<Object?> v = const [],
]) async =>
    (await db
            .customSelect(sql, variables: [for (final x in v) Variable(x)])
            .getSingle())
        .read<int>('c');

void main() {
  group('Drift product admin', () {
    late AxpertDatabase db;
    late DriftProductAdminRepository repo;

    setUp(() async {
      db = await seededDatabase();
      final provider = FixedDatabaseProvider(db);
      final scope = StoreScope()
        ..set(
          storeId: 'demo-store-ozone',
          userId: 'demo-user-admin',
          currency: CurrencyRegistry.inr,
        );
      repo = DriftProductAdminRepository(
        provider: provider,
        uuid: UuidV4Generator(),
        scope: scope,
        inventory: DriftInventoryRepository(
          provider: provider,
          uuid: UuidV4Generator(),
        ),
      );
    });

    tearDown(() => db.close());

    test(
      'create writes product, packaging, barcodes and opening stock',
      () async {
        final id = await repo.create(_draft());
        final detail = (await repo.detail(
          (await repo.catalog()).last.product.id,
        ))!;
        expect(detail.uuid, id);
        expect(detail.product.name, 'Test Cola');
        expect(detail.product.stock, 77);
        expect(detail.balanceMilli, 77000);
        expect(detail.barcodes, ['9990000000001']);
        expect(detail.packagings.single.quantityBaseMilli, 24000);
        expect(
          await _count(
            db,
            'SELECT COUNT(*) AS c FROM product_barcodes WHERE product_id = ? '
            'AND deleted_at IS NULL',
            [id],
          ),
          2,
        );
        expect(
          await _count(
            db,
            "SELECT COUNT(*) AS c FROM inventory_transactions WHERE product_id = ? "
            "AND reason = 'opening' AND quantity_delta_milli = 77000",
            [id],
          ),
          1,
        );
      },
    );

    test(
      'a user product is not in seed_manifest and survives reseed',
      () async {
        final id = await repo.create(_draft());
        expect(
          await _count(
            db,
            "SELECT COUNT(*) AS c FROM seed_manifest WHERE row_id = ?",
            [id],
          ),
          0,
        );
        await seederFor(db).run(reseed: true);
        expect(
          await _count(
            db,
            'SELECT COUNT(*) AS c FROM products WHERE id = ? '
            'AND deleted_at IS NULL',
            [id],
          ),
          1,
        );
        expect(
          await _count(
            db,
            'SELECT COUNT(*) AS c FROM product_packagings WHERE '
            'product_id = ?',
            [id],
          ),
          1,
        );
      },
    );

    test('a duplicate barcode is refused and nothing is written', () async {
      final before = await _count(db, 'SELECT COUNT(*) AS c FROM products');
      await expectLater(
        repo.create(_draft(barcodes: const ['8901234560000'])),
        throwsA(isA<DuplicateBarcodeException>()),
      );
      await expectLater(
        repo.create(
          _draft(
            barcodes: const ['9990000000002'],
            packagings: const [
              PackagingDraft(
                unitId: _carton,
                name: 'Carton',
                quantityBaseMilli: 24000,
                barcode: '8901234560000',
              ),
            ],
          ),
        ),
        throwsA(isA<DuplicateBarcodeException>()),
      );
      expect(await _count(db, 'SELECT COUNT(*) AS c FROM products'), before);
      expect(
        await _count(
          db,
          "SELECT COUNT(*) AS c FROM product_barcodes WHERE barcode = '9990000000002'",
        ),
        0,
      );
    });

    test('invalid drafts are refused', () async {
      await expectLater(
        repo.create(_draft(name: ' ')),
        throwsA(isA<InvalidProductException>()),
      );
      await expectLater(
        repo.create(
          _draft(
            packagings: const [
              PackagingDraft(unitId: _carton, name: 'A', quantityBaseMilli: 0),
            ],
          ),
        ),
        throwsA(isA<InvalidProductException>()),
      );
    });

    test(
      'update changes attributes, packagings and barcodes, not stock',
      () async {
        final id = await repo.create(_draft());
        final legacy = (await repo.catalog()).last.product.id;
        final before = (await repo.detail(legacy))!;
        await repo.update(
          id,
          _draft(
            name: 'Test Cola 2',
            barcodes: const ['9990000000009'],
            packagings: [
              PackagingDraft(
                id: before.packagings.single.id,
                unitId: _carton,
                name: 'Carton',
                quantityBaseMilli: 12000,
                priceMinor: 99900,
              ),
              const PackagingDraft(
                unitId: _pack,
                name: 'Pack',
                quantityBaseMilli: 6000,
              ),
            ],
            opening: 0,
          ),
        );
        final after = (await repo.detail(legacy))!;
        expect(after.product.name, 'Test Cola 2');
        expect(after.barcodes, ['9990000000009']);
        expect(after.packagings.map((p) => p.quantityBaseMilli), [12000, 6000]);
        expect(after.packagings.first.priceMinor, 99900);
        expect(after.balanceMilli, 77000);
        expect(
          await _count(
            db,
            "SELECT COUNT(*) AS c FROM product_barcodes WHERE barcode = '9990000000001' "
            'AND deleted_at IS NULL',
          ),
          0,
        );
      },
    );

    test('deactivate frees barcodes; reactivate restores them', () async {
      final id = await repo.create(_draft());
      await repo.deactivate(id);
      expect((await repo.catalog()).last.active, isFalse);
      // The code is free again for another product.
      final other = await repo.create(
        _draft(code: 'TST002', packagings: const [], opening: 0),
      );
      await expectLater(
        repo.reactivate(id),
        throwsA(isA<DuplicateBarcodeException>()),
      );
      await repo.deactivate(other);
      await repo.reactivate(id);
      expect(
        (await repo.catalog()).any(
          (r) => r.product.code == 'TST001' && r.active,
        ),
        isTrue,
      );
    });

    test('adjustStock writes ledger, balance and cache together', () async {
      final id = await repo.create(_draft());
      await repo.adjustStock(
        uuid: id,
        deltaMilli: -5500,
        reason: AdjustmentReason.damage,
        note: 'dropped',
      );
      final legacy = (await repo.catalog()).last.product.id;
      final d = (await repo.detail(legacy))!;
      expect(d.balanceMilli, 71500);
      expect(d.product.stock, 71);
      final tx = await db
          .customSelect(
            "SELECT reason, quantity_delta_milli AS q, note, user_id FROM "
            "inventory_transactions WHERE product_id = ? AND reason = 'damage'",
            variables: [Variable(id)],
          )
          .getSingle();
      expect(tx.read<int>('q'), -5500);
      expect(tx.read<String>('note'), 'dropped');
      expect(tx.read<String>('user_id'), 'demo-user-admin');
    });

    test('a forced failure rolls the whole adjustment back', () async {
      final id = await repo.create(_draft());
      await db.customStatement(
        "CREATE TRIGGER boom BEFORE UPDATE OF stock ON products BEGIN "
        "SELECT RAISE(ABORT, 'boom'); END",
      );
      await expectLater(
        repo.adjustStock(
          uuid: id,
          deltaMilli: -1000,
          reason: AdjustmentReason.countCorrection,
          note: '',
        ),
        throwsA(anything),
      );
      await db.customStatement('DROP TRIGGER boom');
      final legacy = (await repo.catalog()).last.product.id;
      expect((await repo.detail(legacy))!.balanceMilli, 77000);
      expect(
        await _count(
          db,
          "SELECT COUNT(*) AS c FROM inventory_transactions WHERE product_id = ? "
          "AND reason != 'opening'",
          [id],
        ),
        0,
      );
    });

    test('a failing create leaves no rows behind', () async {
      await db.customStatement(
        "CREATE TRIGGER boom2 BEFORE INSERT ON inventory_balance BEGIN "
        "SELECT RAISE(ABORT, 'boom'); END",
      );
      final before = await _count(db, 'SELECT COUNT(*) AS c FROM products');
      await expectLater(repo.create(_draft()), throwsA(anything));
      expect(await _count(db, 'SELECT COUNT(*) AS c FROM products'), before);
      expect(
        await _count(
          db,
          "SELECT COUNT(*) AS c FROM product_packagings WHERE name = 'Carton' "
          "AND quantity_base_milli = 24000 AND product_id NOT IN "
          "(SELECT id FROM products)",
        ),
        0,
      );
    });

    test('stock below zero is blocked when the store forbids it', () async {
      final id = await repo.create(_draft(opening: 2000));
      await expectLater(
        repo.adjustStock(
          uuid: id,
          deltaMilli: -3000,
          reason: AdjustmentReason.countCorrection,
          note: '',
        ),
        throwsA(isA<AdjustmentBlockedException>()),
      );
    });

    test('stock views list packaging levels', () async {
      await repo.create(_draft());
      final legacy = (await repo.catalog()).last.product.id;
      final view = (await repo.stockViews())[legacy]!;
      expect(view.balanceMilli, 77000);
      expect(view.levels.single.quantityBaseMilli, 24000);
    });

    test('categories can be created inline', () async {
      final c = await repo.createCategory('Frozen');
      final sub = await repo.createCategory('Ice cream', parentId: c.id);
      final all = await repo.categories();
      expect(all.any((x) => x.id == sub.id && x.parentId == c.id), isTrue);
    });
  });

  group('Mock product admin', () {
    late MockProductAdminRepository repo;
    setUp(() {
      MockDelay.provider = () => Duration.zero;
      repo = MockProductAdminRepository(
        products: MockProductRepository(InMemoryLocalStore()),
      );
    });

    test('same rules: validation, duplicate barcode, adjust', () async {
      final ProductAdminRepository r = repo;
      final id = await r.create(_draft());
      await expectLater(
        r.create(_draft(code: 'X')),
        throwsA(isA<DuplicateBarcodeException>()),
      );
      await r.adjustStock(
        uuid: id,
        deltaMilli: -1000,
        reason: AdjustmentReason.damage,
        note: '',
      );
      expect((await r.stockViews()).values.single.balanceMilli, 76000);
      await r.deactivate(id);
      expect((await r.catalog()).single.active, isFalse);
    });
  });
}
