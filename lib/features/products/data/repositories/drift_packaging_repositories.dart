import 'package:drift/drift.dart';

import '../../../../core/database/axpert_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../domain/entities/packaging_entities.dart';
import '../../domain/repositories/packaging_repositories.dart';

int _systemNow() => DateTime.now().millisecondsSinceEpoch;

/// Units read from `units` (global rows, seeded by the schema).
class DriftUnitRepository implements UnitRepository {
  DriftUnitRepository(this._provider);

  final DatabaseProvider _provider;

  @override
  Future<List<MeasureUnit>> all() async {
    final db = await _provider.open();
    final rows =
        await (db.select(db.unitEntries)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.code)]))
            .get();
    return [for (final r in rows) _unit(r)];
  }

  @override
  Future<MeasureUnit?> byCode(String code) async {
    final db = await _provider.open();
    final row =
        await (db.select(db.unitEntries)
              ..where((t) => t.code.equals(code) & t.deletedAt.isNull()))
            .getSingleOrNull();
    return row == null ? null : _unit(row);
  }

  static MeasureUnit _unit(UnitEntry r) => MeasureUnit(
    id: r.id,
    code: r.code,
    name: r.name,
    kind: UnitKind.fromCode(r.kind),
  );
}

class DriftBrandRepository implements BrandRepository {
  DriftBrandRepository(this._provider, {int Function()? now})
    : _now = now ?? _systemNow;

  final DatabaseProvider _provider;
  final int Function() _now;

  @override
  Future<List<Brand>> all() async {
    final db = await _provider.open();
    final rows =
        await (db.select(db.brandEntries)
              ..where((t) => t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .get();
    return [for (final r in rows) Brand(id: r.id, name: r.name)];
  }

  @override
  Future<void> save(Brand brand) async {
    final db = await _provider.open();
    final now = _now();
    await db.durableTransaction(() async {
      final updated =
          await (db.update(
            db.brandEntries,
          )..where((t) => t.id.equals(brand.id))).write(
            BrandEntriesCompanion(
              name: Value(brand.name),
              updatedAt: Value(now),
              deletedAt: const Value(null),
            ),
          );
      if (updated == 0) {
        await db
            .into(db.brandEntries)
            .insert(
              BrandEntriesCompanion.insert(
                id: brand.id,
                name: brand.name,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
  }

  @override
  Future<void> remove(String id) async {
    final db = await _provider.open();
    final now = _now();
    await db.durableTransaction(
      () => (db.update(db.brandEntries)..where((t) => t.id.equals(id))).write(
        BrandEntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      ),
    );
  }
}

class DriftPackagingRepository implements PackagingRepository {
  DriftPackagingRepository(this._provider, {int Function()? now})
    : _now = now ?? _systemNow;

  final DatabaseProvider _provider;
  final int Function() _now;

  @override
  Future<List<ProductPackaging>> forProduct(String productId) async {
    final db = await _provider.open();
    return forProductWithin(db, productId);
  }

  static Future<List<ProductPackaging>> forProductWithin(
    AxpertDatabase db,
    String productId,
  ) async {
    final rows =
        await (db.select(db.packagingEntries)
              ..where(
                (t) => t.productId.equals(productId) & t.deletedAt.isNull(),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.sortOrder),
                (t) => OrderingTerm.asc(t.quantityBaseMilli),
              ]))
            .get();
    return [for (final r in rows) toEntity(r)];
  }

  @override
  Future<Map<int, SellableUnits>> sellableByLegacyId() async {
    final db = await _provider.open();
    final packs =
        await (db.select(db.packagingEntries)
              ..where((t) => t.enabled.equals(true) & t.deletedAt.isNull())
              ..orderBy([
                (t) => OrderingTerm.asc(t.sortOrder),
                (t) => OrderingTerm.asc(t.quantityBaseMilli),
              ]))
            .get();
    if (packs.isEmpty) return const <int, SellableUnits>{};
    final ids = <String>{for (final p in packs) p.productId};
    final products = await (db.select(
      db.productEntries,
    )..where((t) => t.id.isIn(ids) & t.deletedAt.isNull())).get();
    final units = {
      for (final u in await db.select(db.unitEntries).get()) u.id: u.name,
    };
    final byUuid = {for (final p in products) p.id: p};
    final grouped = <int, List<ProductPackaging>>{};
    for (final p in packs) {
      final product = byUuid[p.productId];
      if (product == null) continue;
      grouped.putIfAbsent(product.legacyId, () => []).add(toEntity(p));
    }
    return <int, SellableUnits>{
      for (final e in grouped.entries)
        e.key: SellableUnits(
          baseUnitName:
              units[products
                  .firstWhere((p) => p.legacyId == e.key)
                  .baseUnitId] ??
              '',
          packagings: e.value,
        ),
    };
  }

  @override
  Future<void> save(ProductPackaging p) async {
    final db = await _provider.open();
    final now = _now();
    await db.durableTransaction(() async {
      final clash =
          await (db.select(db.packagingEntries)..where(
                (t) =>
                    t.productId.equals(p.productId) &
                    t.unitId.equals(p.unitId) &
                    t.deletedAt.isNull() &
                    t.id.equals(p.id).not(),
              ))
              .get();
      if (clash.isNotEmpty) {
        throw DuplicatePackagingException(p.productId, p.unitId);
      }
      final updated =
          await (db.update(
            db.packagingEntries,
          )..where((t) => t.id.equals(p.id))).write(
            PackagingEntriesCompanion(
              unitId: Value(p.unitId),
              name: Value(p.name),
              quantityBaseMilli: Value(p.quantityBaseMilli),
              sku: Value(p.sku),
              priceMinor: Value(p.priceMinor),
              sortOrder: Value(p.sortOrder),
              enabled: Value(p.enabled),
              updatedAt: Value(now),
              deletedAt: const Value(null),
            ),
          );
      if (updated == 0) {
        await db
            .into(db.packagingEntries)
            .insert(
              PackagingEntriesCompanion.insert(
                id: p.id,
                productId: p.productId,
                unitId: p.unitId,
                name: p.name,
                quantityBaseMilli: p.quantityBaseMilli,
                sku: Value(p.sku),
                priceMinor: Value(p.priceMinor),
                sortOrder: Value(p.sortOrder),
                enabled: Value(p.enabled),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
  }

  @override
  Future<void> remove(String id) async {
    final db = await _provider.open();
    final now = _now();
    await db.durableTransaction(
      () =>
          (db.update(db.packagingEntries)..where((t) => t.id.equals(id))).write(
            PackagingEntriesCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
            ),
          ),
    );
  }

  static ProductPackaging toEntity(PackagingEntry r) => ProductPackaging(
    id: r.id,
    productId: r.productId,
    unitId: r.unitId,
    name: r.name,
    quantityBaseMilli: r.quantityBaseMilli,
    sku: r.sku,
    priceMinor: r.priceMinor,
    sortOrder: r.sortOrder,
    enabled: r.enabled,
  );
}

class DriftBarcodeRepository implements BarcodeRepository {
  DriftBarcodeRepository(this._provider, {int Function()? now})
    : _now = now ?? _systemNow;

  final DatabaseProvider _provider;
  final int Function() _now;

  @override
  Future<BarcodeMatch?> findByBarcode(String? storeId, String barcode) async {
    final db = await _provider.open();
    final query =
        db.select(db.barcodeEntries).join([
            innerJoin(
              db.productEntries,
              db.productEntries.id.equalsExp(db.barcodeEntries.productId),
            ),
          ])
          ..where(
            db.barcodeEntries.barcode.equals(barcode) &
                db.barcodeEntries.deletedAt.isNull() &
                db.productEntries.deletedAt.isNull() &
                (storeId == null
                    ? const Constant(true)
                    : db.barcodeEntries.storeId.equals(storeId)),
          )
          ..orderBy([OrderingTerm.asc(db.barcodeEntries.createdAt)])
          ..limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    final code = row.readTable(db.barcodeEntries);
    final product = row.readTable(db.productEntries);
    ProductPackaging? packaging;
    if (code.packagingId != null) {
      final p =
          await (db.select(db.packagingEntries)..where(
                (t) => t.id.equals(code.packagingId!) & t.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      // A code of a removed packaging must not sell the base unit.
      if (p == null) return null;
      packaging = DriftPackagingRepository.toEntity(p);
    }
    return BarcodeMatch(
      productId: product.id,
      productLegacyId: product.legacyId,
      barcode: code.barcode,
      packaging: packaging,
    );
  }

  @override
  Future<List<ProductBarcode>> forProduct(String productId) async {
    final db = await _provider.open();
    final rows =
        await (db.select(db.barcodeEntries)
              ..where(
                (t) => t.productId.equals(productId) & t.deletedAt.isNull(),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return [
      for (final r in rows)
        ProductBarcode(
          id: r.id,
          productId: r.productId,
          barcode: r.barcode,
          packagingId: r.packagingId,
          storeId: r.storeId,
        ),
    ];
  }

  @override
  Future<void> save(ProductBarcode b) async {
    final db = await _provider.open();
    final now = _now();
    await db.durableTransaction(() async {
      final clash = await db
          .customSelect(
            'SELECT 1 FROM product_barcodes WHERE barcode = ? AND id != ? '
            "AND deleted_at IS NULL AND COALESCE(store_id, '') = ?",
            variables: [
              Variable<String>(b.barcode),
              Variable<String>(b.id),
              Variable<String>(b.storeId ?? ''),
            ],
          )
          .get();
      if (clash.isNotEmpty) throw DuplicateBarcodeException(b.barcode);
      final updated =
          await (db.update(
            db.barcodeEntries,
          )..where((t) => t.id.equals(b.id))).write(
            BarcodeEntriesCompanion(
              productId: Value(b.productId),
              packagingId: Value(b.packagingId),
              storeId: Value(b.storeId),
              barcode: Value(b.barcode),
              updatedAt: Value(now),
              deletedAt: const Value(null),
            ),
          );
      if (updated == 0) {
        await db
            .into(db.barcodeEntries)
            .insert(
              BarcodeEntriesCompanion.insert(
                id: b.id,
                productId: b.productId,
                packagingId: Value(b.packagingId),
                storeId: Value(b.storeId),
                barcode: b.barcode,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
  }

  @override
  Future<void> remove(String id) async {
    final db = await _provider.open();
    final now = _now();
    await db.durableTransaction(
      () => (db.update(db.barcodeEntries)..where((t) => t.id.equals(id))).write(
        BarcodeEntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      ),
    );
  }
}
